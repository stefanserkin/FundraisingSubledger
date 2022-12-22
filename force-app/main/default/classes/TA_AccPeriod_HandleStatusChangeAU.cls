public with sharing class TA_AccPeriod_HandleStatusChangeAU implements TriggerAction.AfterUpdate {
    
    public void afterUpdate(
        List<Accounting_Period__c> newList, 
        List<Accounting_Period__c> oldList
    ) {
        // Identify accounting periods with changed statuses
        Map<Id, Accounting_Period__c> oldMap = new Map<Id, Accounting_Period__c>(oldList);
        Set<Id> setPeriodIds = new Set<Id>();
        for (Accounting_Period__c ap : newList) {
            if (
                ap.Status__c != oldMap.get(ap.Id).Status__c
            ) {
                setPeriodIds.add(ap.Id);
            }
        }

        // Get jes for identified accounting periods
        List<Journal_Entry__c> lstEntriesToUpdate = new List<Journal_Entry__c>();
        lstEntriesToUpdate = [
            SELECT Id, Posting_Status__c 
              FROM Journal_Entry__c 
             WHERE Accounting_Period__c IN :setPeriodIds 
               AND Posting_Status__c != :fsl_Constants.JE_STATUS_DENIED
             LIMIT 10000
        ];


        for (Journal_Entry__c je : lstEntriesToUpdate) {
            
        }



        /*
        @testVisible 
    static final String AP_STATUS_OPEN = 'Open';
    @testVisible 
    static final String AP_STATUS_CLOSED = 'Closed';
    @testVisible 
    static final String JE_STATUS_ENTERED = 'Entered';
    @testVisible 
    static final String JE_STATUS_POSTED = 'Posted';
    @testVisible 
    static final String JE_STATUS_DENIED = 'Denied';
    */

    }

}
