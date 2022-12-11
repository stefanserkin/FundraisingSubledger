public with sharing class fsl_AccountingJobBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Opportunity';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> lstOpportunities) {
        // Calculate stuff
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
        email.setSubject(apexJob.Status + ': Fundraising Accounting Job Batch');
        email.setPlainTextBody('The fsl_AccountingJobBatch ran and processed ' + apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

}