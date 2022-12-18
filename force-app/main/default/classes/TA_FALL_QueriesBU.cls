public class TA_FALL_QueriesBU {

    private static TA_FALL_QueriesBU instance;

    private TA_FALL_QueriesBU() {}

    public static TA_FALL_QueriesBU getInstance() {
        if (TA_FALL_QueriesBU.instance == null) {
            TA_FALL_QueriesBU.instance = new TA_FALL_QueriesBU();
        }
        return TA_FALL_QueriesBU.instance;
    }

    public Map<Id, Future_Allocation_Set__c> mapSets { get; private set; }

    /*****************************************************
    * Called by metadata trigger handler
    * Manage from sObject Trigger Settings mdt: Future Allocation
    ******************************************************/

    public class Service implements TriggerAction.BeforeUpdate {

        public void beforeUpdate(List<Future_Allocation__c> newList, List<Future_Allocation__c> oldList) {
            TA_FALL_QueriesBU.getInstance().mapSets = getSetMap(newList);
        }

        private Map<Id, Future_Allocation_Set__c> getSetMap(
            List<Future_Allocation__c> newList
        ) {
            Set<Id> setFasIds = new Set<Id>();
            for (Future_Allocation__c fa : newList) setFasIds.add(fa.Future_Allocation_Set__c);
            Map<Id, Future_Allocation_Set__c> mapSets = new Map<Id, Future_Allocation_Set__c>([
                SELECT Id, Opportunity__c, Opportunity__r.Amount, 
                       (SELECT Id, Amount__c, Percent__c 
                          FROM Future_Allocations__r)
                  FROM Future_Allocation_Set__c
                 WHERE Id IN :setFasIds
            ]);
            return mapSets;
        }

    }

}
