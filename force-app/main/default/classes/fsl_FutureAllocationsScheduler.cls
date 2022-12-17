public with sharing class fsl_FutureAllocationsScheduler implements Schedulable {
    public static String schedule = '0 12 0 ? * *'; // Every day at 12:12am

    public static String run() {
        fsl_FutureAllocationsScheduler fas = new fsl_FutureAllocationsScheduler();
        return System.schedule('FSL Future Allocations Batch', schedule, fas);
    }

    public void execute(SchedulableContext context) {
        fsl_FutureAllocationsBatch fab = new fsl_FutureAllocationsBatch();
        Id batchId = Database.executeBatch(fab, 50);
    }
}
