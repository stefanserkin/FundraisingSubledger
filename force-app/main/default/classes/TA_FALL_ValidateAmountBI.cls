public with sharing class TA_FALL_ValidateAmountBI implements TriggerAction.BeforeInsert {

    private static Map<Id, Future_Allocation_Set__c> mapSets;

    public void beforeInsert(List<Future_Allocation__c> newList) {
        // Get sets with child records
        mapSets = TA_FALL_QueriesBI.getInstance().mapSets;

        // Group records in trigger by set
        Map<Id, List<Future_Allocation__c>> mapSetToTriggerFalls;
        mapSetToTriggerFalls = new Map<Id, List<Future_Allocation__c>>();
        for (Future_Allocation__c fall : newList) {
            if (!mapSetToTriggerFalls.containsKey(fall.Future_Allocation_Set__c)) {
                mapSetToTriggerFalls.put(
                    fall.Future_Allocation_Set__c, 
                    new List<Future_Allocation__c>()
                );
            }
            List<Future_Allocation__c> lstUpdatedFalls = mapSetToTriggerFalls.get(fall.Future_Allocation_Set__c);
            lstUpdatedFalls.add(fall);
            mapSetToTriggerFalls.put(
                fall.Future_Allocation_Set__c, 
                lstUpdatedFalls
            );
        }

        // Check that total value of each set does not exceed opp total
        for (Future_Allocation__c curfall : newList) {
            Decimal oppTotal = mapSets.get(curfall.Future_Allocation_Set__c)?.Opportunity__r.Amount;
            Decimal setTotal = 0;

            for (Future_Allocation__c tFall : mapSetToTriggerFalls.get(curfall.Future_Allocation_Set__c)) {
                setTotal += tFall.Amount__c != null ? tFall.Amount__c : 0;
            }
            for (Future_Allocation__c setFall : mapSets.get(curfall.Future_Allocation_Set__c).Future_Allocations__r) {
                setTotal += setFall.Amount__c;
            }

            if (setTotal > oppTotal) {
                String errorMessage = 'The amount allocated in the set must not exceed the opportunity amount of $' + oppTotal;
                curfall.addError(errorMessage);
            }
        }
        
    }

}
