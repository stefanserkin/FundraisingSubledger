public class TA_FALL_QueriesBI {

    private static TA_FALL_QueriesBI instance;

    private TA_FALL_QueriesBI() {}

    public static TA_FALL_QueriesBI getInstance() {
        if (TA_FALL_QueriesBI.instance == null) {
            TA_FALL_QueriesBI.instance = new TA_FALL_QueriesBI();
        }
        return TA_FALL_QueriesBI.instance;
    }

    public Map<Id, Future_Allocation_Set__c> mapSets { get; private set; }

    /*****************************************************
    * Called by metadata trigger handler
    * Manage from sObject Trigger Settings mdt: Future Allocation
    ******************************************************/

    public class Service implements TriggerAction.BeforeInsert {

        public void beforeInsert(List<Future_Allocation__c> newList) {
            TA_FALL_QueriesBI.getInstance().mapSets = getSetMap(newList);
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
