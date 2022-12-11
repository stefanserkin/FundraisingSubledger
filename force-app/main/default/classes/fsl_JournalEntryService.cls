public without sharing class fsl_JournalEntryService {

    // Constants - common labels
    public static final String ACCOUNTING_STATE_UNCOMMITTED = 'Uncommitted';
    public static final String ACCOUNTING_STATE_COMMITTED = 'Committed';
    public static final String ACCOUNTING_STATE_FINALIZED = 'Finalized';
    public static final String RECEIVABLES_ACCOUNT_NAME = 'Pledges_Receivable';
    public static final String GLOBAL_GL_TYPE_RECEIVABLES = 'Receivables';
    public static final String GLOBAL_GL_TYPE_PAYMENT = 'Payment';
    public static final String DEBIT_LABEL = 'Debit';
    public static final String CREDIT_LABEL = 'Credit';

    // Global settings and configuration cache
    private static Fundraising_Subledger_Setting__mdt appSettings = Fundraising_Subledger_Setting__mdt.getAll().values().get(0);
    private static Accounting_Period__c openAccountingPeriod;
    private static Map<String, String> mapStageToState;
    private static Map<String, Global_GL_Account__mdt> mapLabelToGlobalAccount;
    private static Global_GL_Account__mdt defaultReceivablesAccount;
    private static Global_GL_Account__mdt defaultPaymentAccount;
    private static Map<String, String> mapGLCodeToName;

    private static Set<Id> setUpdatedOppIds;

    /***************************
     * Main entry - record triggered events on opportunity, payment, and allocation
     *   that have accounting impact should call this method
     * @param Set<Id> Set of opportunity ids where changes occurred
     ***************************/

    public static void createEntries(
        Set<Id> setOpportunityIds
    ) {
        System.debug('::::: entered main entry');
        // List of jes to insert
        List<Journal_Entry__c> lstJEsToInsert = new List<Journal_Entry__c>();
        // If necessary, instantiate cache variables
        initializeCache();
        // Get opportunities with details
        Map<Id, Opportunity> mapOpportunities = getOppsWithAccountingDetails(setOpportunityIds);
        for (Opportunity opp : mapOpportunities.values()) {
            // Create map of relevant GLs and expected net
            Map<String, Decimal> mapExpectedNets = getExpectedNetMap(opp);
            Map<String, Decimal> mapCurrentNets = getCurrentNetMap(opp.Journal_Entries__r);
            if (mapExpectedNets.isEmpty()) {
                // zero stuff out
            } else {
                // Find changes to gl attributions
                for (String glCode : mapExpectedNets.keySet()) {
                    Decimal expectedValue = mapExpectedNets.get(glCode);
                    Decimal currentValue = mapCurrentNets.containsKey(glCode) ? mapExpectedNets.get(glCode) : 0;
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

        if (!lstJEsToInsert.isEmpty()) {
            insert lstJEsToInsert;
        }

    }

    /**
     * Initialize cached collections
     */

    private static void initializeCache() {
        if (setUpdatedOppIds == null) setUpdatedOppIds = new Set<Id>();
        if (mapGLCodeToName == null) mapGLCodeToName = new Map<String, String>();
        defaultPaymentAccount = getDefaultPaymentAccount();
        defaultReceivablesAccount = getDefaultReceivablesAccount();
    }

    /**
     * Get new journal entry
     * @param Opportunity opp The opportunity for this journal entry
     * @param String glCode The gl code to debit/credit
     * @param Decimal delta The amount of the je - net of credit
     * @return Journal_Entry__c A journal entry ready to be inserted
     */

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

    /**
     * Get map of expected GL net values
     * @param Opportunity opp Opportunity with child payments and allocations
     * @return Map<String, Decimal> Map of GL codes and expected net totals
     */

    private static Map<String, Decimal> getExpectedNetMap(Opportunity opp) {
        Map<String, Decimal> mapExpectedNets = new Map<String, Decimal>();
        // Get opp accounting state
        Map<String, String> mapStageToState = getStageToStateMappings();
        String strState = getStageToStateMappings().get(opp.StageName);
        // Uncommitted opps should have zero dollars in each account
        // Write off existing attributions for Closed Lost
        if (strState == ACCOUNTING_STATE_UNCOMMITTED) return mapExpectedNets;
        // For committed and finalized opps, calculate expected net per GL
        //   from payments and allocations
        String glCode = '';
        for (npe01__OppPayment__c p : opp.npe01__OppPayment__r) {
            // Get gl code from map or set the default
            glCode = p.npe01__Payment_Method__c != null && getGlobalAccountMap().containsKey(p.npe01__Payment_Method__c)
                ? getGlobalAccountMap().get(p.npe01__Payment_Method__c).GL_Code__c
                : getDefaultPaymentAccount().GL_Code__c;
            // Add gl to map
            if (!mapExpectedNets.containsKey(glCode)) {
                mapExpectedNets.put(glCode, 0);
            }
            // Subtract amount of paid GL for payment accounts
            mapExpectedNets.put(glCode, mapExpectedNets.get(glCode) - p.npe01__Payment_Amount__c);
        }
        for (npsp__Allocation__c a : opp.npsp__Allocations__r) {
            glCode = a.npsp__General_Accounting_Unit__r.GL_Code__c;
            // Add gl to map
            if (!mapExpectedNets.containsKey(glCode)) {
                mapExpectedNets.put(glCode, 0);
            }
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

    /**
     * Get map of current GL net values from journal entries
     * @param Journal_Entry__c[] lstJEs List of journal entries to assess
     * @return Map<String, Decimal> Map of existing GL codes to their net totals
     */

    private static Map<String, Decimal> getCurrentNetMap(List<Journal_Entry__c> lstJEs) {
        Map<String, Decimal> mapCurrentNets = new Map<String, Decimal>();
        String glCode = '';
        for (Journal_Entry__c je : lstJEs) {
            glCode = je.GL_Code__c;
            if (!mapCurrentNets.containsKey(glCode)) {
                mapCurrentNets.put(glCode, 0);
            }
            Decimal netValue = mapCurrentNets.get(glCode);
            // Positive value for credits, negative for debits
            netValue += je.Type__c == DEBIT_LABEL ? (je.Amount__c) * -1 : je.Amount__c;
            mapCurrentNets.put(glCode, netValue);
        }
        return mapCurrentNets;
    }

    /**
     * Returns the open accounting period
     * Only one accounting period may be open at a time
     * @return Accounting_Period__c open accounting period
     */

     public static Accounting_Period__c getOpenAccountingPeriod() {
        if (openAccountingPeriod == null) {
            openAccountingPeriod = [
                SELECT Id, Start_Date__c, End_Date__c, Status__c 
                  FROM Accounting_Period__c 
                 WHERE Status__c = :appSettings.Accounting_Period_Open_Status__c 
                 LIMIT 1
            ];
        }
        return openAccountingPeriod;
    }

    /**
     * @return Map<String, String> Map of opportunity stages to corresponding accounting state
     */

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

    /**
     * @param set<Id> set of opportunity ids
     * @return Opportunity[] Opps with payments and allocations
     */

    public static Map<Id, Opportunity> getOppsWithAccountingDetails(
        Set<Id> setOpportunityIds
    ) {
        return new Map<Id, Opportunity>([
            SELECT Id, Amount, CloseDate, StageName, AccountId, IsWon, npe01__Amount_Outstanding__c, 
                   (SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Paid__c
                      FROM npe01__OppPayment__r
                     WHERE npe01__Paid__c = true), 
                   (SELECT Id, npsp__Amount__c, npsp__General_Accounting_Unit__c, npsp__General_Accounting_Unit__r.Name, npsp__General_Accounting_Unit__r.GL_Code__c 
                      FROM npsp__Allocations__r), 
                   (SELECT Id, Amount__c, GL_Code__c, Type__c 
                      FROM Journal_Entries__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
             LIMIT 10000
        ]);
    }

    /**
     * Return map of payment accounts by label from cache
     * @return Map<String, Global_GL_Account__mdt>
     */

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
            }
        }
        return mapLabelToGlobalAccount;
    }

    /**
     * Get global payment account
     * @return Global_GL_Account__mdt
     */

    public static Global_GL_Account__mdt getDefaultPaymentAccount() {
        if (defaultPaymentAccount == null) {
            for (Global_GL_Account__mdt acc : getGlobalAccountMap().values()) {
                if (acc.Id == appSettings.Default_Payment_Account__c) {
                    defaultPaymentAccount = acc;
                    mapGLCodeToName.put(acc.GL_Code__c, acc.GL_Account_Name__c);
                    System.debug(':::: added default gl code: ' + acc.GL_Code__c);
                    System.debug(':::: with name: ' + acc.GL_Account_Name__c);
                    break;
                }
            }
        }
        return defaultPaymentAccount;
    }

    /**
     * Get global payment account
     * @return Global_GL_Account__mdt
     */

    public static Global_GL_Account__mdt getDefaultReceivablesAccount() {
        if (defaultReceivablesAccount == null) {
            for (Global_GL_Account__mdt acc : getGlobalAccountMap().values()) {
                if (acc.Id == appSettings.Default_Receivables_Account__c) {
                    defaultReceivablesAccount = acc;
                    mapGLCodeToName.put(acc.GL_Code__c, acc.GL_Account_Name__c);
                    break;
                }
            }
        }
        return defaultReceivablesAccount;
    }

}
