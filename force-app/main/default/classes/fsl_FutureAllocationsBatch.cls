public with sharing class fsl_FutureAllocationsBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Opportunity WHERE Id IN (SELECT Opportunity__c FROM Future_Allocation_Set__c WHERE Effective_Date__c = TODAY)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        System.debug(':::: batch query found ' + lstOpportunities.size() + ' records');
        Set<Id> setOppIds = new Set<Id>();
        for (Opportunity opp : lstOpportunities) setOppIds.add(opp.Id);
        fsl_FutureAllocationsHandler.reallocate(setOppIds);
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [
            SELECT Id, 
                   Status, 
                   NumberOfErrors, 
                   JobItemsProcessed, 
                   TotalJobItems, 
                   CreatedBy.Email
              FROM AsyncApexJob 
             WHERE Id = :bc.getJobId()
        ];
        
        // Send email to job creator with batch results
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        email.setToAddresses(toAddress);
        email.setSubject(apexJob.Status + ': Future Allocations Batch');
        email.setPlainTextBody('The fsl_FutureAllocationsBatch ran and processed ' + apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
}
