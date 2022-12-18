public with sharing class TA_FALL_ValidateAmountBU implements TriggerAction.BeforeUpdate {

    private static Map<Id, Future_Allocation_Set__c> mapSets;

    public void beforeUpdate(
        List<Future_Allocation__c> newList, 
        List<Future_Allocation__c> oldList
    ) {
        // Get sets with child records
        mapSets = TA_FALL_QueriesBU.getInstance().mapSets;

        Map<Id, Future_Allocation__c> newMap = new Map<Id, Future_Allocation__c>(newList);

        // Group records in trigger by set
        Map<Id, List<Future_Allocation__c>> mapSetIdToFalls = new Map<Id, List<Future_Allocation__c>>();
        for (Future_Allocation__c fall : newList) {
            if (!mapSetIdToFalls.containsKey(fall.Future_Allocation_Set__c)) {
                mapSetIdToFalls.put(
                    fall.Future_Allocation_Set__c, 
                    new List<Future_Allocation__c>()
                );
            }
            List<Future_Allocation__c> lstUpdatedFalls = mapSetIdToFalls.get(fall.Future_Allocation_Set__c);
            lstUpdatedFalls.add(fall);
            mapSetIdToFalls.put(
                fall.Future_Allocation_Set__c, 
                lstUpdatedFalls
            );
        }

        // Add existing allocations that have not been changed to map
        for (Future_Allocation_Set__c fSet : mapSets.values()) {
            for (Future_Allocation__c setFall : fSet.Future_Allocations__r) {
                if (newMap.containsKey(setFall.Id)) {
                    continue;
                }
                List<Future_Allocation__c> lstUpdatedFalls = mapSetIdToFalls.get(fSet.Id);
                lstUpdatedFalls.add(setFall);
                mapSetIdToFalls.put(
                    fSet.Id, 
                    lstUpdatedFalls
                );
            }
        }

        // Check that total value of each set does not exceed opp total
        for (Future_Allocation__c curfall : newList) {
            Decimal oppTotal = mapSets.get(curfall.Future_Allocation_Set__c)?.Opportunity__r.Amount;
            Decimal setTotal = 0;
            for (Future_Allocation__c tFall : mapSetIdToFalls.get(curfall.Future_Allocation_Set__c)) {
                setTotal += tFall.Amount__c != null ? tFall.Amount__c : 0;
            }
            if (setTotal > oppTotal) {
                String errorMessage = 'The amount allocated in the set must not exceed the opportunity amount of $' + oppTotal;
                curfall.addError(errorMessage);
            }
        }

    }

}
