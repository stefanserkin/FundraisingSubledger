public with sharing class TA_AccPeriod_PostEntriesAU implements TriggerAction.AfterUpdate {

    @testVisible 
    private static final String AP_STATUS_CLOSED = 'Closed';
    @testVisible 
    private static final String JE_STATUS_POSTED = 'Posted';
    @testVisible 
    private static final String JE_STATUS_DENIED = 'Denied';

    public void afterUpdate(
        List<Accounting_Period__c> newList, List<Accounting_Period__c> oldList
    ) {
        // Identify newly closed accounting periods
        Map<Id, Accounting_Period__c> oldMap = new Map<Id, Accounting_Period__c>(oldList);
        Set<Id> setPeriodIds = new Set<Id>();
        for (Accounting_Period__c ap : newList) {
            if (
                ap.Status__c == AP_STATUS_CLOSED && 
                oldMap.get(ap.Id).Status__c != AP_STATUS_CLOSED
            ) {
                setPeriodIds.add(ap.Id);
            }
        }

        // Update jes for closed periods that have not been 'denied'
        List<Journal_Entry__c> lstEntriesToUpdate = new List<Journal_Entry__c>();
        Set<String> setInvalidStatuses = new Set<String>{JE_STATUS_POSTED,JE_STATUS_DENIED};
        lstEntriesToUpdate = [
            SELECT Id, Posting_Status__c 
              FROM Journal_Entry__c 
             WHERE Accounting_Period__c IN :setPeriodIds 
               AND Posting_Status__c NOT IN :setInvalidStatuses
             LIMIT 10000
        ];

        for (Journal_Entry__c je : lstEntriesToUpdate) {
            je.Posting_Status__c = JE_STATUS_POSTED;
        }

        if (!lstEntriesToUpdate.isEmpty()) {
            try {
                update lstEntriesToUpdate;
            } catch (Exception e) {
                System.debug('::::: An exception occurred: ' + e.getMessage());
            }
        }

    }

}
