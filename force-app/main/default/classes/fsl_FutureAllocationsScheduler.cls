public with sharing class fsl_FutureAllocationsScheduler implements Schedulable {
    public static String schedule = '0 15 1 ? * *'; // Every day at 1:15am

    public static String run() {
        fsl_FutureAllocationsScheduler ajs = new fsl_FutureAllocationsScheduler();
        return System.schedule('Fundraising Subledger Batch', schedule, ajs);
    }

    public void execute(SchedulableContext context) {
        fsl_AccountingJobBatch ajb = new fsl_AccountingJobBatch();
        Id batchId = Database.executeBatch(ajb, 50);
    }
}
