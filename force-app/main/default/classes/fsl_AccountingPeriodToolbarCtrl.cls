public with sharing class fsl_AccountingPeriodToolbarCtrl {
    
    @AuraEnabled
    public static String unpostEntries(String recordId) {
        try {
            List<Journal_Entry__c> lstEntries = [
                SELECT Id, Posting_Status__c, Post_Date__c 
                  FROM Journal_Entry__c 
                 WHERE Accounting_Period__c = :recordId 
                 LIMIT 10000
            ];
            for (Journal_Entry__c je : lstEntries) {
                je.Posting_Status__c = 'Entered';
                je.Post_Date__c = null;
            }
            update lstEntries;
            return 'Success';
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}
