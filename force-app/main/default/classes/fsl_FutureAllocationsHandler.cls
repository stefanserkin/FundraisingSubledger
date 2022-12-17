public inherited sharing class fsl_FutureAllocationsHandler {
    
    public static void reallocate(Set<Id> setOpportunityIds) {
        System.debug('::::: you found Waldo.');
        
        List<npsp__Allocation__c> lstAllocsToInsert = new List<npsp__Allocation__c>();
        List<npsp__Allocation__c> lstAllocsToUpdate = new List<npsp__Allocation__c>();
        List<npsp__Allocation__c> lstAllocsToDelete = new List<npsp__Allocation__c>();

        // Get opps with allocations
        Map<Id, Opportunity> mapOppsWithAllocations = new map<Id, Opportunity>([
            SELECT Id, 
                   (SELECT Id, npsp__General_Accounting_Unit__c, npsp__Amount__c, npsp__Percent__c
                      FROM npsp__Allocations__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
        ]);

        for (Opportunity opp : mapOppsWithAllocations.values()) {
            for (npsp__Allocation__c alloc : opp.npsp__Allocations__r) {
                lstAllocsToDelete.add(alloc);
            }
        }

        if (!lstAllocsToDelete.isEmpty()) {
            delete lstAllocsToDelete;
        }

        // Get future allocation sets with future allocations effective today
        List<Future_Allocation_Set__c> lstSets = [
            SELECT Id, 
                   Effective_Date__c, 
                   Opportunity__c, 
                   (SELECT Id, 
                           General_Accounting_Unit__c, 
                           General_Accounting_Unit__r.Name, 
                           General_Accounting_Unit__r.GL_Code__c, 
                           Amount__c, 
                           Percent__c
                      FROM Future_Allocations__r)
              FROM Future_Allocation_Set__c 
             WHERE Opportunity__c IN :setOpportunityIds
               AND Effective_Date__c = today
        ];

        for (Future_Allocation_Set__c fSet : lstSets) {
            for (Future_Allocation__c fAlloc : fSet.Future_Allocations__r) {
                lstAllocsToInsert.add(
                    new npsp__Allocation__c(
                        npsp__Opportunity__c = fSet.Opportunity__c, 
                        npsp__General_Accounting_Unit__c = fAlloc.General_Accounting_Unit__c, 
                        npsp__Amount__c = fAlloc.Amount__c
                    )
                );
            }
        }

        if (!lstAllocsToInsert.isEmpty()) {
            insert lstAllocsToInsert;
        }

        /*
        // Create map of lists of future sets by opportunity id
        Map<Id, List<Future_Allocation_Set__c>> mapOppIdToFutureSets = new Map<Id, List<Future_Allocation_Set__c>>();
        for (Future_Allocation_Set__c fSet : lstSets) {
            if (mapOppIdToFutureSets.containsKey(fSet.Opportunity__c)) {
                List<Future_Allocation_Set__c> lstUpdatedSets = mapOppIdToFutureSets.get(fSet.Opportunity__c);
                lstUpdatedSets.add(fSet);
                mapOppIdToFutureSets.put(
                    fSet.Opportunity__c, 
                    lstUpdatedSets
                );
            } else {
                mapOppIdToFutureSets.put(
                    fSet.Opportunity__c, 
                    new List<Future_Allocation_Set__c>{fSet}
                );
            }
        }

        // Get opps with allocations
        Map<Id, Opportunity> mapOppsWithAllocations = new map<Id, Opportunity>([
            SELECT Id, 
                   (SELECT Id, npsp__General_Accounting_Unit__c, npsp__Amount__c, npsp__Percent__c
                      FROM npsp__Allocations__r)
              FROM Opportunity
             WHERE Id IN :setOpportunityIds
        ]);

        // Calculate adjustments and separate by dml type
        for (Id oppId : setOpportunityIds) {
            List<Future_Allocation_Set__c> lstOppSets = mapOppIdToFutureSets.get(oppId);
            List<Future_Allocation__c> lstOppFutureAllocs = new List<Future_Allocation__c>();
            for (Future_Allocation_Set__c fSet : lstOppSets) {
                lstOppFutureAllocs.addAll(fSet.Future_Allocations__r);
            } 
            Map<Id, Future_Allocation__c> mapGauToFutureAlloc = new Map<Id, Future_Allocation__c>();
            for (Future_Allocation__c fAlloc : lstOppFutureAllocs) {
                mapGauToFutureAlloc.put(fAlloc.General_Accounting_Unit__c, fAlloc);
            }
            Opportunity oppWithExistingAllocs = mapOppsWithAllocations.get(oppId);
            // Store ids of gaus that have already been reviewed to avoid checking twice
            Set<Id> setReviewedGauIds = new Set<Id>();
            // Loop through existing allocations to look for adjustments
            for (npsp__Allocation__c exAlloc : oppWithExistingAllocs.npsp__Allocations__r) {
                // If there is a matching future allocation, update the existing allocation amount
                if (mapGauToFutureAlloc.containsKey(exAlloc.npsp__General_Accounting_Unit__c)) {
                    Decimal futureAmount = mapGauToFutureAlloc.get(exAlloc.npsp__General_Accounting_Unit__c).Amount__c;
                    if (futureAmount != exAlloc.npsp__Amount__c) {
                        exAlloc.npsp__Amount__c = futureAmount;
                        lstAllocsToUpdate.add(exAlloc);
                    }
                } else { // Otherwise, add the existing allocation to be deleted
                    lstAllocsToDelete.add(exAlloc);
                }
                setReviewedGauIds.add(exAlloc.npsp__General_Accounting_Unit__c);
            }
            // Loop through future allocations to find anything net-new
            for (Future_Allocation__c fAlloc : lstOppFutureAllocs) {
                if (!setReviewedGauIds.contains(fAlloc.General_Accounting_Unit__c)) {
                    lstAllocsToInsert.add(
                        new npsp__Allocation__c(
                            npsp__Opportunity__c = oppId, 
                            npsp__General_Accounting_Unit__c = fAlloc.General_Accounting_Unit__c, 
                            npsp__Amount__c = fAlloc.Amount__c, 
                            npsp__Percent__c = fAlloc.Percent__c
                        )
                    );
                }
            }
        }

        if (!lstAllocsToInsert.isEmpty()) {
            insert lstAllocsToInsert;
        }
        if (!lstAllocsToDelete.isEmpty()) {
            delete lstAllocsToDelete;
        }
        if (!lstAllocsToUpdate.isEmpty()) {
            update lstAllocsToUpdate;
        }
        */

    }

}
