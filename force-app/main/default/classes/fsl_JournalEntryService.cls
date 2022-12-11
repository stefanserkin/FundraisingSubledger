public without sharing class fsl_JournalEntryService {

    public static final String ACCOUNTING_STATE_UNCOMMITTED = 'Uncommitted';
    public static final String ACCOUNTING_STATE_COMMITTED = 'Committed';
    public static final String ACCOUNTING_STATE_FINALIZED = 'Finalized';

    // Global settings
    private static Fundraising_Subledger_Setting__mdt appSettings = Fundraising_Subledger_Setting__mdt.getAll().values().get(0);

    // Cache configuration
    private static Accounting_Period__c openAccountingPeriod;
    private static Map<String, String> mapStageToState;
    private static Map<String, Global_GL_Account__mdt> mapPaymentAccounts;
    private static Global_GL_Account__mdt receivablesAccount;

    // Labeling
    private static final String GLOBAL_GL_TYPE_PAYMENT = 'Payment';
    private static final String RECEIVABLES_ACCOUNT_NAME = 'Receivables';
    private static final String DEBIT_LABEL = 'Debit';
    private static final String CREDIT_LABEL = 'Credit';

    /***************************
     * Main entry - record triggered events on opportunity, payment, and allocation
     *   that have accounting impact should call this method
     * @param Set<Id> Set of opportunity ids where changes occurred
     ***************************/

    public static void createEntries(Set<Id> setOpportunityIds) {
        
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
     * @return Map<String, String> map of opportunity stages to corresponding
     *   accounting state
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
     * @return Opportunity[] opps with payments and allocations
     */

    public static Map<Id, Opportunity> getOppsWithAccountingDetails(
        Set<Id> setOpportunityIds
    ) {
        return new Map<Id, Opportunity>([
            SELECT Id, Amount, CloseDate, StageName, AccountId, IsWon, 
                   (SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Method__c, npe01__Paid__c 
                      FROM npe01__OppPayment__r), 
                   (SELECT Id, npsp__Amount__c, npsp__General_Accounting_Unit__c, npsp__General_Accounting_Unit__r.Name, npsp__General_Accounting_Unit__r.GL_Code__c 
                      FROM npsp__Allocations__r), 
                   (SELECT Id, Debit__c, Credit__c, GL_Code__c 
                      FROM Journal_Entries__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
             LIMIT 10000
        ]);
    }

    /**
     * @return Map<String, Global_GL_Account__mdt> map of payment accounts
     */

    public static Map<String, Global_GL_Account__mdt> getPaymentAccountMap() {
        if (mapPaymentAccounts == null) {
            mapPaymentAccounts = new Map<String, Global_GL_Account__mdt>();
            List<Global_GL_Account__mdt> lstAccounts = [
                SELECT Id, Label, GL_Code__c, GL_Account_Name__c 
                  FROM Global_GL_Account__mdt 
                 WHERE Type__c = :GLOBAL_GL_TYPE_PAYMENT
                 LIMIT 10000
            ];
            for (Global_GL_Account__mdt glAcc : lstAccounts) {
                mapPaymentAccounts.put(glAcc.Label, glAcc);
            }
        }
        return mapPaymentAccounts;
    }

    /**
     * @return Global_GL_Account__mdt receivable global gl account
     */

     public static Global_GL_Account__mdt getReceivablesAccount() {
        if (receivablesAccount == null) {
            receivablesAccount = Global_GL_Account__mdt.getInstance(RECEIVABLES_ACCOUNT_NAME);
        }
        return receivablesAccount;
     }

}
