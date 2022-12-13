public with sharing class fsl_AccountingJobScheduler implements Schedulable {

    public static String schedule = '0 6 0 ? * *'; // Every day at 12:06am

    public static String run() {
        fsl_AccountingJobScheduler ajs = new fsl_AccountingJobScheduler();
        return System.schedule('Fundraising Subledger Batch', schedule, ajs);
    }

    public void execute(SchedulableContext context) {
        fsl_AccountingJobBatch ajb = new fsl_AccountingJobBatch();
        Id batchId = Database.executeBatch(ajb, 50);
    }
    
}
