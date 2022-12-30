public without sharing class fsl_JournalEntryService {

    /******************************************************
     * STATIC VARIABLES
     ******************************************************/

    // Global settings and configuration cache
    private static Fundraising_Subledger_Setting__mdt appSettings = Fundraising_Subledger_Setting__mdt.getAll().values().get(0);
    private static Accounting_Period__c openAccountingPeriod;
    private static Map<String, String> mapStageToState;
    private static Map<String, Global_GL_Account__mdt> mapLabelToGlobalAccount;
    private static Map<String, String> mapGLCodeToName;
    private static Map<Id, npe01__OppPayment__c> mapWrittenOffPayments; 
    private static Global_GL_Account__mdt defaultReceivablesAccount;
    private static Global_GL_Account__mdt defaultPaymentAccount;
    private static Global_GL_Account__mdt defaultWriteOffAccount;
    private static Set<Id> setUpdatedOppIds;

    // Constants - common labels
    public static final String ACCOUNTING_STATE_UNCOMMITTED = fsl_Constants.ACCOUNTING_STATE_UNCOMMITTED;
    public static final String ACCOUNTING_STATE_COMMITTED = fsl_Constants.ACCOUNTING_STATE_COMMITTED;
    public static final String ACCOUNTING_STATE_FINALIZED = fsl_Constants.ACCOUNTING_STATE_FINALIZED;
    public static final String RECEIVABLES_ACCOUNT_NAME = fsl_Constants.RECEIVABLES_ACCOUNT_NAME;
    public static final String GLOBAL_GL_TYPE_RECEIVABLES = fsl_Constants.GLOBAL_GL_TYPE_RECEIVABLES;
    public static final String GLOBAL_GL_TYPE_PAYMENT = fsl_Constants.GLOBAL_GL_TYPE_PAYMENT;
    public static final String DEBIT_LABEL = fsl_Constants.DEBIT_LABEL;
    public static final String CREDIT_LABEL = fsl_Constants.CREDIT_LABEL;

    /******************************************************
     * PUBLIC METHODS
     ******************************************************/

    /***************************
     * Main entry - record triggered events on opportunity, payment, and allocation
     *   that have accounting impact should call this method
     * @param Set<Id> Set of opportunity ids where changes have occurred
     ***************************/

    public static void createEntries(
        Set<Id> setOpportunityIds
    ) {
        // Initialize cached variables and store default data
        initializeCache();
        // Get opportunities with details
        Map<Id, Opportunity> mapOpportunities = getOppsWithAccountingDetails( setOpportunityIds );
        // Get journal entries representing the delta for any relevant gl accounts
        List<Journal_Entry__c> lstJEsToInsert = generateJournalEntries( mapOpportunities );
        // Insert journal entries
        if (!lstJEsToInsert.isEmpty()) insert lstJEsToInsert;
    }

    /***************************
     * Get global payment account
     * @return Global_GL_Account__mdt
     ***************************/

     public static Global_GL_Account__mdt getDefaultPaymentAccount() {
        if (defaultPaymentAccount == null) {
            for (Global_GL_Account__mdt acc : getGlobalAccountMap().values()) {
                if (acc.Id == appSettings.Default_Payment_Account__c) {
                    defaultPaymentAccount = acc;
                    break;
                }
            }
        }
        return defaultPaymentAccount;
    }

    /***************************
     * Get global payment account
     * @return Global_GL_Account__mdt
     ***************************/

    public static Global_GL_Account__mdt getDefaultReceivablesAccount() {
        if (defaultReceivablesAccount == null) {
            for (Global_GL_Account__mdt acc : getGlobalAccountMap().values()) {
                if (acc.Id == appSettings.Default_Receivables_Account__c) {
                    defaultReceivablesAccount = acc;
                    break;
                }
            }
        }
        return defaultReceivablesAccount;
    }

    /***************************
     * Returns the open accounting period
     * @return Accounting_Period__c
     ***************************/

     public static Accounting_Period__c getOpenAccountingPeriod() {
        if (openAccountingPeriod == null) {
            openAccountingPeriod = [
                SELECT Id, Start_Date__c, End_Date__c, Status__c 
                  FROM Accounting_Period__c 
                 WHERE Status__c = :appSettings.Accounting_Period_Open_Status__c 
                   AND Start_Date__c <= TODAY
                   AND End_Date__c >= TODAY
                 LIMIT 1
            ];
        }
        return openAccountingPeriod;
    }

    /***************************
     * @return Map<String, String> Map of opportunity stages to corresponding accounting state
     ***************************/

    public static Map<String, String> getStageToStateMappings() {
        if (mapStageToState == null) {
            mapStageToState = new Map<String, String>();
            List<Accounting_State_Mapping__mdt> lstMappings = Accounting_State_Mapping__mdt.getAll().values();
            for (Accounting_State_Mapping__mdt asm : lstMappings) {
                mapStageToState.put(
                    asm.Opportunity_Stage__c, 
                    asm.Accounting_State__c
                );
            }
        }
        return mapStageToState;
    }

    /******************************************************
     * PRIVATE METHODS
     ******************************************************/

    /***************************
     * Initialize cache
     ***************************/

     private static void initializeCache() {
        if (setUpdatedOppIds == null) setUpdatedOppIds = new Set<Id>();
        if (mapGLCodeToName == null) mapGLCodeToName = new Map<String, String>();
        defaultPaymentAccount = getDefaultPaymentAccount();
        defaultReceivablesAccount = getDefaultReceivablesAccount();
    }

    /***************************
     * Generate journal entries for a collection of opportunities
     * @param Map<Id, Opportunity> mapOpportunities Opps with related payments, allocations, and jes
     * @return Journal_Entry__c[] A list of jes ready to insert
     ***************************/

    private static List<Journal_Entry__c> generateJournalEntries(
        Map<Id, Opportunity> mapOpportunities
    ) {

        List<Journal_Entry__c> lstJEsToInsert = new List<Journal_Entry__c>();
        // Create map of payment ids to payment allocations
        Map<Id, List<npe01__OppPayment__c>> mapPaymentIdToAllocations = new Map<Id, List<npe01__OppPayment__c>>();
        // Get map of written off payments
        loadWrittenOffPaymentMap(mapOpportunities);

        for (Opportunity opp : mapOpportunities.values()) {
            // Exit if override is set
            if (opp.Do_Not_Create_Journal_Entries__c) continue;
            
            // Create map of relevant GLs and expected net
            Map<String, Decimal> mapExpectedNets = getExpectedNetMap(opp);
            Map<String, Decimal> mapCurrentNets = getCurrentNetMap(opp.Journal_Entries__r);

            if (mapExpectedNets.isEmpty()) {
                System.debug('::::: mapExpectedNets is empty');
                // TODO - ZERO STUFF OUT
            } else {
                // Find changes to gl attributions
                for (String glCode : mapExpectedNets.keySet()) {
                    Decimal expectedValue = mapExpectedNets.get(glCode);
                    Decimal currentValue = mapCurrentNets.containsKey(glCode) ? mapCurrentNets.get(glCode) : 0;
                    if (expectedValue != currentValue) {
                        Decimal delta = expectedValue - currentValue;
                        lstJEsToInsert.add( 
                            getNewJournalEntry(opp, glCode, delta)
                        );
                        setUpdatedOppIds.add(opp.Id);
                    }
                }
            }
            // Loop through current gls to off-set any that are not in the map of expected nets
            for (String glCode : mapCurrentNets.keySet()) {
                if (
                    !mapExpectedNets.containsKey(glCode) && 
                    mapCurrentNets.get(glCode) != 0
                ) {
                    lstJEsToInsert.add(
                        getNewJournalEntry(opp, glCode, (mapCurrentNets.get(glCode) * -1))
                    );
                    setUpdatedOppIds.add(opp.Id);
                }
            }
        }

        return lstJEsToInsert;
    }

    /***************************
     * Get map of written off payments and their allocations
     * @param Map<Id, Opportunity> map of opps with payments, allocs, and jes
     * @return Map<Id, npe01__OppPayment__c> Map of written off payments with payment allocations
     ***************************/

    private static void loadWrittenOffPaymentMap(
        Map<Id, Opportunity> mapOpportunities
    ) {
        if (mapWrittenOffPayments == null) {
            Set<Id> setWrittenOffPaymentIds = new Set<Id>();
            for (Opportunity opp : mapOpportunities.values()) {
                for (npe01__OppPayment__c p : opp.npe01__OppPayment__r) {
                    if (p.npe01__Written_Off__c) setWrittenOffPaymentIds.add(p.Id);
                }
            }
            // If any written off payments are found, get payments with payment allocations
            if (!setWrittenOffPaymentIds.isEmpty()) {
                mapWrittenOffPayments = new Map<Id, npe01__OppPayment__c>([
                    SELECT Id, npe01__Payment_Amount__c, 
                           (SELECT Id, npsp__Amount__c, npsp__General_Accounting_Unit__c, Write_Off_GL_Code__c 
                              FROM npsp__Allocations__r)
                      FROM npe01__OppPayment__c
                     WHERE Id IN :setWrittenOffPaymentIds
                     LIMIT 10000
                ]);
            } else {
                mapWrittenOffPayments = new Map<Id, npe01__OppPayment__c>();
            }
        }
    }

    /***************************
     * Get map of expected GL net values
     * @param Opportunity opp Opportunity with child payments and allocations
     * @return Map<String, Decimal> Map of GL codes and expected net totals
     ***************************/

    private static Map<String, Decimal> getExpectedNetMap(
        Opportunity opp
    ) {
        Map<String, Decimal> mapExpectedNets = new Map<String, Decimal>();
        // Get opp accounting state
        // Map<String, String> mapStageToState = getStageToStateMappings();
        String strState = getStageToStateMappings().get(opp.StageName);
        // Uncommitted opps should have zero dollars in each account
        // Write off existing attributions for Closed Lost
        if (strState == ACCOUNTING_STATE_UNCOMMITTED) return mapExpectedNets;
        // For committed and finalized opps, calculate expected net per GL
        // from payments and allocations
        String glCode = '';
        for (npe01__OppPayment__c p : opp.npe01__OppPayment__r) {
            if (p.npe01__Written_Off__c) {
                // Get written off amount
                Decimal writeOffAmount = p.npe01__Payment_Amount__c;
                Decimal writtenOffAmount = 0;
                // Get list of payment allocations from map
                List<npsp__Allocation__c> lstPaymentAllocations;
                lstPaymentAllocations = mapWrittenOffPayments.get(p.Id)?.npsp__Allocations__r;
                // For each payment allocation, calculate net amount to gl
                for (npsp__Allocation__c alloc : lstPaymentAllocations) {
                    glCode = alloc.Write_Off_GL_Code__c;
                    if (!mapExpectedNets.containsKey(glCode)) mapExpectedNets.put(glCode, 0);
                    mapExpectedNets.put(glCode, mapExpectedNets.get(glCode) - alloc.npsp__Amount__c);
                    writtenOffAmount += alloc.npsp__Amount__c;
                }
                // Write off remaining amount to default gl
                if (writtenOffAmount < writeOffAmount) {
                    Decimal delta = writeOffAmount - writtenOffAmount;
                    glCode = defaultWriteOffAccount.GL_Code__c;
                    if (!mapExpectedNets.containsKey(glCode)) mapExpectedNets.put(glCode, 0);
                    mapExpectedNets.put(glCode, mapExpectedNets.get(glCode) - delta);
                }
            } else if (p.npe01__Paid__c) {
                // Get gl code from map or set the default
                glCode = p.npe01__Payment_Method__c != null && getGlobalAccountMap().containsKey(p.npe01__Payment_Method__c)
                    ? getGlobalAccountMap().get(p.npe01__Payment_Method__c).GL_Code__c
                    : getDefaultPaymentAccount().GL_Code__c;
                // Add gl to map
                if (!mapExpectedNets.containsKey(glCode)) mapExpectedNets.put(glCode, 0);
                // Subtract amount of paid GL for payment accounts
                mapExpectedNets.put(glCode, mapExpectedNets.get(glCode) - p.npe01__Payment_Amount__c);
            }
            // Do stock stuff - fees, delta of selling price to received price, gl account to alter with liquidated amount (selling price)
        }

        for (npsp__Allocation__c a : opp.npsp__Allocations__r) {
            glCode = a.npsp__General_Accounting_Unit__r.GL_Code__c;
            // Add gl to map
            if (!mapExpectedNets.containsKey(glCode)) mapExpectedNets.put(glCode, 0);
            // Add amount of paid GL for allocation accounts
            mapExpectedNets.put(glCode, mapExpectedNets.get(glCode) + a.npsp__Amount__c);
            mapGLCodeToName.put(glCode, a.npsp__General_Accounting_Unit__r.Name);
        }

        // Get expected receivables amount by subtracting payments from total opp amount
        if (
            strState == ACCOUNTING_STATE_COMMITTED && 
            opp.npe01__Amount_Outstanding__c > 0
        ) {
            mapExpectedNets.put(
                defaultReceivablesAccount.GL_Code__c, 
                (opp.npe01__Amount_Outstanding__c * -1)
            );
        }
        
        return mapExpectedNets;
    }

    /***************************
     * Get map of current GL net values from journal entries
     * @param Journal_Entry__c[] lstJEs List of journal entries to assess
     * @return Map<String, Decimal> Map of existing GL codes to their net totals
     ***************************/

    private static Map<String, Decimal> getCurrentNetMap(
        List<Journal_Entry__c> lstJEs
    ) {
        Map<String, Decimal> mapCurrentNets = new Map<String, Decimal>();
        String glCode = '';
        for (Journal_Entry__c je : lstJEs) {
            glCode = je.GL_Code__c;
            // Add gl to map
            if (!mapCurrentNets.containsKey(glCode)) mapCurrentNets.put(glCode, 0);
            Decimal netValue = mapCurrentNets.get(glCode);
            // Assign a positive value to credits, negative to debits
            netValue += je.Type__c == DEBIT_LABEL ? (je.Amount__c * -1) : je.Amount__c;
            mapCurrentNets.put(glCode, netValue);
            mapGLCodeToName.put(glCode, je.GL_Account_Name__c);
        }
        return mapCurrentNets;
    }

    /***************************
     * Get new journal entry
     * @param Opportunity opp The opportunity for this journal entry
     * @param String glCode The gl code to debit/credit
     * @param Decimal delta The amount of the je - net of credit
     * @return Journal_Entry__c A journal entry ready to be inserted
     ***************************/

     private static Journal_Entry__c getNewJournalEntry(
        Opportunity opp, 
        String glCode, 
        Decimal delta
    ) {
        Journal_Entry__c je = new Journal_Entry__c();
        je.Accounting_Period__c = getOpenAccountingPeriod().Id;
        je.Opportunity__c = opp.Id;
        je.Account__c = opp.AccountId;
        je.Type__c = delta > 0 ? CREDIT_LABEL : DEBIT_LABEL;
        je.Amount__c = Math.abs(delta);
        je.Date__c = Date.today();
        je.GL_Account_Name__c = mapGLCodeToName.get(glCode);
        je.GL_Code__c = glCode;
        je.Posting_Status__c = appSettings.Default_Journal_Entry_Posting_Status__c;
        return je;
    }

    /***************************
     * @param set<Id> Set of opportunity ids
     * @return Opportunity[] Opps with payments, allocations, and jes
     ***************************/

    @testVisible
    private static Map<Id, Opportunity> getOppsWithAccountingDetails(
        Set<Id> setOpportunityIds
    ) {
        return new Map<Id, Opportunity>([
            SELECT Id, Amount, CloseDate, StageName, AccountId, IsWon, npe01__Amount_Outstanding__c, Do_Not_Create_Journal_Entries__c, 
                   (SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Paid__c, npe01__Written_Off__c
                      FROM npe01__OppPayment__r
                     WHERE npe01__Paid__c = true
                        OR npe01__Written_Off__c = true), 
                   (SELECT Id, npsp__Amount__c, npsp__General_Accounting_Unit__c, npsp__General_Accounting_Unit__r.Name, npsp__General_Accounting_Unit__r.GL_Code__c 
                      FROM npsp__Allocations__r), 
                   (SELECT Id, Amount__c, GL_Code__c, GL_Account_Name__c, Type__c 
                      FROM Journal_Entries__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
             LIMIT 10000
        ]);
    }

    /***************************
     * Return map of payment accounts by label from cache
     * @return Map<String, Global_GL_Account__mdt>
     ***************************/

    private static Map<String, Global_GL_Account__mdt> getGlobalAccountMap() {
        if (mapLabelToGlobalAccount == null) {
            mapLabelToGlobalAccount = new Map<String, Global_GL_Account__mdt>();
            List<Global_GL_Account__mdt> lstAccounts = [
                SELECT Id, Label, GL_Code__c, GL_Account_Name__c 
                  FROM Global_GL_Account__mdt 
                 LIMIT 10000
            ];
            for (Global_GL_Account__mdt glAcc : lstAccounts) {
                mapLabelToGlobalAccount.put(glAcc.Label, glAcc);
                mapGLCodeToName.put(glAcc.GL_Code__c, glAcc.GL_Account_Name__c);
                if (glAcc.Id == appSettings.Default_Payment_Account__c) {
                    defaultPaymentAccount = glAcc;
                } else if (glAcc.Id == appSettings.Default_Receivables_Account__c) {
                    defaultReceivablesAccount = glAcc;
                } else if (glAcc.Id == appSettings.Default_Write_Off_Account__c) {
                    defaultWriteOffAccount = glAcc;
                }
            }
        }
        return mapLabelToGlobalAccount;
    }

}
