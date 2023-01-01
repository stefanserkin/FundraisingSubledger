public with sharing class TA_AccPeriod_PostEntriesAU implements TriggerAction.AfterUpdate {

    public void afterUpdate(
        List<Accounting_Period__c> newList, List<Accounting_Period__c> oldList
    ) {
        // Identify newly closed accounting periods
        Map<Id, Accounting_Period__c> oldMap = new Map<Id, Accounting_Period__c>(oldList);
        Set<Id> setPeriodIds = new Set<Id>();
        for (Accounting_Period__c ap : newList) {
            if (
                ap.Status__c == fsl_Constants.AP_STATUS_CLOSED && 
                oldMap.get(ap.Id).Status__c != fsl_Constants.AP_STATUS_CLOSED
            ) {
                setPeriodIds.add(ap.Id);
            }
        }

        // Update jes for closed periods that have not been denied
        List<Journal_Entry__c> lstEntriesToUpdate = new List<Journal_Entry__c>();
        Set<String> setInvalidStatuses = new Set<String>{fsl_Constants.JE_STATUS_POSTED, fsl_Constants.JE_STATUS_DENIED};
        lstEntriesToUpdate = [
            SELECT Id, Posting_Status__c, Post_Date__c, Accounting_Period__r.Last_Post_Date__c 
              FROM Journal_Entry__c 
             WHERE Accounting_Period__c IN :setPeriodIds 
               AND Posting_Status__c NOT IN :setInvalidStatuses
             LIMIT 10000
        ];

        for (Journal_Entry__c je : lstEntriesToUpdate) {
            je.Posting_Status__c = fsl_Constants.JE_STATUS_POSTED;
            je.Post_Date__c = je.Accounting_Period__r.Last_Post_Date__c != null 
                ? je.Accounting_Period__r.Last_Post_Date__c
                : Date.today();
        }

        if (!lstEntriesToUpdate.isEmpty()) {
            try {
                update lstEntriesToUpdate;
            } catch (DmlException e) {
                System.debug('::::: An exception occurred: ' + e.getMessage());
            }
        }

    }

}
