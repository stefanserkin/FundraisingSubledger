// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Schedule accounting job
// fsl_AccountingJobScheduler.run();

List<Future_Allocation_Set__c> lstSetsToInsert = new List<Future_Allocation_Set__c>();
List<Future_Allocation__c> lstAllsToInsert = new List<Future_Allocation__c>();

List<Future_Allocation_Set__c> lstSets = [
    SELECT Id, Name, Effective_Date__c, Opportunity__c, 
           (SELECT Id, General_Accounting_Unit__c, General_Accounting_Unit__r.Name, Amount__c, Percent__c 
              FROM Future_Allocations__r)
      FROM Future_Allocation_Set__c
];

System.debug(lstSets);

for (Integer i = 0; i < 4; I++) {
    Future_Allocation_Set__c newSet = new Future_Allocation_Set__c();
    newSet.Effective_Date__c = lstSets.get(0).Effective_Date__c.addDays(i+1);
    newSet.Opportunity__c = lstSets.get(0).Opportunity__c;
    lstSetsToInsert.add(newSet);
}

insert lstSetsToInsert;

String strRestrictedName = 'General Fund (Restricted)';
String strUnrestrictedName = 'General Fund (Unrestricted)';
Integer allocCount = 1;
Decimal totalGift = 100000;

for (Future_Allocation_Set__c futureSet : lstSetsToInsert) {
    for (Future_Allocation__c fAlloc : lstSets[0].Future_Allocations__r) {
        Future_Allocation__c a = new Future_Allocation__c();
        a.Future_Allocation_Set__c = futureSet.Id;
        a.General_Accounting_Unit__c = fAlloc.General_Accounting_Unit__c;
        if (fAlloc.General_Accounting_Unit__r.Name == strUnrestrictedName) {
            a.Amount__c = fAlloc.Amount__c * (allocCount+1);
            a.Percent__c = fAlloc.Percent__c * (allocCount+1);
        } else if (fAlloc.General_Accounting_Unit__r.Name == strRestrictedName) {
            a.Amount__c = totalGift - (fAlloc.Amount__c * (allocCount+1));
            a.Percent__c = 100 - (fAlloc.Percent__c * (allocCount+1));
        }
        lstAllsToInsert.add(a);
    }
}

insert lstAllsToInsert;
