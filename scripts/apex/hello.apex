// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Schedule accounting job
// fsl_AccountingJobScheduler.run();
// fsl_FutureAllocationsScheduler.run();

Map<Id, Future_Allocation_Set__c> mapSets = new Map<Id, Future_Allocation_Set__c>([
    SELECT Id, Opportunity__c, Opportunity__r.Amount, 
           (SELECT Id, Amount__c, Percent__c 
              FROM Future_Allocations__r)
      FROM Future_Allocation_Set__c
]);

for (Id setId : mapSets.keySet()) {
    if (mapSets.get(setId).Future_Allocations__r.isEmpty()) {
        System.debug('::: found an empty one. Size: ' + mapSets.get(setId).Future_Allocations__r.size());
        mapSets.put(
            setId, 
            mapSets.get(setId).Future_Allocations__r.add(
                new Future_Allocation__c(
                    Amount__c = 100
                )
            )
        );
        
        System.debug('::: after add. Size: ' + mapSets.get(setId).Future_Allocations__r.size());
    }
}
