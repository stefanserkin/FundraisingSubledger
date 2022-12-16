public inherited sharing class fsl_FutureAllocationsHandler {
    
    public static void reallocate(Set<Id> setOpportunityIds) {
        System.debug('::::: you found Waldo.');

        List<npsp__Allocation__c> lstAllocsToInsert = new List<npsp__Allocation__c>();
        List<npsp__Allocation__c> lstAllocsToDelete = new List<npsp__Allocation__c>();

        // Get future allocation sets with allocations

        Map<Id, Opportunity> mapOppsWithAllocations = new map<Id, Opportunity>([
            SELECT Id, 
                   (SELECT Id
                      FROM npsp__Allocations__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
        ]);

        List<Future_Allocation_Set__c> lstSets = [
            SELECT Id, 
                   Effective_Date__c, 
                   Opportunity__c, 
                   (SELECT Id, 
                           General_Accounting_Unit__c, 
                           General_Accounting_Unit__r.Name, 
                           Amount__c, 
                           Percent__c
                      FROM Future_Allocations__r)
              FROM Future_Allocation_Set__c 
             WHERE Opportunity__c IN :setOpportunityIds
        ];

    }

}
