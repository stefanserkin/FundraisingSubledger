public with sharing class fsl_ManualAdjustmentController {

    // Cache map of gl accounts
    private static Map<Id, GlAccountWrapper> mapGlAccountWrappers;

    /****************************************************
     * Return list of objects with gl ids, names and codes
     ****************************************************/
    
    @AuraEnabled(cacheable=true)
    public static List<GlAccountWrapper> getGlAccounts() {
        try {
            if (mapGlAccountWrappers == null) {
                mapGlAccountWrappers = new Map<Id, GlAccountWrapper>();
                Set<String> setLabels = new Set<String>();
                // Add all gaus
                List<npsp__General_Accounting_Unit__c> lstGaus = [
                    SELECT Id, Name, GL_Code__c 
                      FROM npsp__General_Accounting_Unit__c 
                     WHERE GL_Code__c != null
                     ORDER BY Name ASC
                     LIMIT 10000
                ];
                for (npsp__General_Accounting_Unit__c gau : lstGaus) {
                    String label = gau.Name + ' (' + gau.GL_Code__c + ')';
                    if (!setLabels.contains(label)) {
                        GlAccountWrapper wrapper = new GlAccountWrapper();
                        wrapper.id = gau.Id;
                        wrapper.name = gau.Name;
                        wrapper.code = gau.GL_Code__c;
                        wrapper.label = label;
                        wrapper.isGau = true;
                        mapGlAccountWrappers.put(wrapper.Id, wrapper);
                        setLabels.add(label);
                    }
                }
                // Add all global accounts
                for (Global_GL_Account__mdt ggl : Global_GL_Account__mdt.getAll().values()) {
                    String label = ggl.GL_Account_Name__c + ' (' + ggl.GL_Code__c + ')';
                    if (!setLabels.contains(label)) {
                        GlAccountWrapper wrapper = new GlAccountWrapper();
                        wrapper.id = ggl.Id;
                        wrapper.name = ggl.GL_Account_Name__c;
                        wrapper.code = ggl.GL_Code__c;
                        wrapper.label = label;
                        wrapper.isGau = false;
                        mapGlAccountWrappers.put(wrapper.Id, wrapper);
                        setLabels.add(label);
                    }
                }
            }

            return mapGlAccountWrappers.values();

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String createAdjustmentJournalEntries(
        String accountingPeriodId, 
        Date jeDate, 
        Decimal jeAmount, 
        String jeDebitAccountId, 
        String jeCreditAccountId, 
        String jeNotes
    ) {
        try {
            List<Journal_Entry__c> lstJEsToInsert = new List<Journal_Entry__c>();

            // Load account map
            getGlAccounts();

            System.debug(':::: accountingPeriodId: ' + accountingPeriodId);

            // Debit entry
            Journal_Entry__c jeDebit = new Journal_Entry__c();
            GlAccountWrapper debitWrapper = mapGlAccountWrappers.get(jeDebitAccountId);
            jeDebit.Accounting_Period__c = accountingPeriodId;
            jeDebit.Manual_Adjustment__c = true;
            jeDebit.Type__c = 'Debit';
            jeDebit.Amount__c = jeAmount;
            jeDebit.Date__c = jeDate;
            jeDebit.GL_Account_Name__c = debitWrapper.name;
            jeDebit.GL_Code__c = debitWrapper.code;
            jeDebit.Posting_Status__c = 'Entered';
            jeDebit.General_Accounting_Unit__c = debitWrapper.isGau ? debitWrapper.id : null;
            jeDebit.Notes__c = jeNotes;
            lstJEsToInsert.add(jeDebit);

            // Credit entry
            Journal_Entry__c jeCredit = new Journal_Entry__c();
            GlAccountWrapper creditWrapper = mapGlAccountWrappers.get(jeCreditAccountId);
            jeCredit.Accounting_Period__c = accountingPeriodId;
            jeCredit.Manual_Adjustment__c = true;
            jeCredit.Type__c = 'Credit';
            jeCredit.Amount__c = jeAmount;
            jeCredit.Date__c = jeDate;
            jeCredit.GL_Account_Name__c = creditWrapper.name;
            jeCredit.GL_Code__c = creditWrapper.code;
            jeCredit.Posting_Status__c = 'Entered';
            jeCredit.General_Accounting_Unit__c = creditWrapper.isGau ? creditWrapper.id : null;
            jeCredit.Notes__c = jeNotes;
            lstJEsToInsert.add(jeCredit);

            insert lstJEsToInsert;

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /****************************************************
     * Wrapper to unify gaus and global accounts
     ****************************************************/

    public class GlAccountWrapper {
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String code {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public Boolean isGau {get;set;}
    }

}
