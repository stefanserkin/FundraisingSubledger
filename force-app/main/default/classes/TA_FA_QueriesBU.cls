public class TA_FA_QueriesBU {

    private static TA_FA_QueriesBU instance;

    private TA_FA_QueriesBU() {}

    public static TA_FA_QueriesBU getInstance() {
        if (TA_FA_QueriesBU.instance == null) {
            TA_FA_QueriesBU.instance = new TA_FA_QueriesBU();
        }
        return TA_FA_QueriesBU.instance;
    }

    public Map<Id, Future_Allocation_Set__c> mapSets { get; private set; }

    /*****************************************************
    * Called by metadata trigger handler
    * Manage from sObject Trigger Settings mdt: Future Allocation
    ******************************************************/

    public class Service implements TriggerAction.BeforeUpdate {

        public void beforeUpdate(List<Future_Allocation__c> newList, List<Future_Allocation__c> oldList) {
            TA_FA_QueriesBU.getInstance().mapSets = getSetMap(newList);
        }

        private Map<Id, Future_Allocation_Set__c> getSetMap(
            List<Future_Allocation__c> newList
        ) {
            Set<Id> setFasIds = new Set<Id>();
            for (Future_Allocation__c fa : newList) setFasIds.add(fa.Future_Allocation_Set__c);
            Map<Id, Future_Allocation_Set__c> mapSets = new Map<Id, Future_Allocation_Set__c>([
                SELECT Id, Opportunity__r.Amount
                  FROM Future_Allocation_Set__c
                 WHERE Id IN :setFasIds
            ]);
            return mapSets;
        }

    }

}
