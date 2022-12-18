public class TA_FA_QueriesBI {

    private static TA_FA_QueriesBI instance;

    private TA_FA_QueriesBI() {}

    public static TA_FA_QueriesBI getInstance() {
        if (TA_FA_QueriesBI.instance == null) {
            TA_FA_QueriesBI.instance = new TA_FA_QueriesBI();
        }
        return TA_FA_QueriesBI.instance;
    }

    public Map<Id, Future_Allocation_Set__c> mapSets { get; private set; }

    /*****************************************************
    * Called by metadata trigger handler
    * Manage from sObject Trigger Settings mdt: Future Allocation
    ******************************************************/

    public class Service implements TriggerAction.BeforeInsert {

        public void beforeInsert(List<Future_Allocation__c> newList) {
            TA_FA_QueriesBI.getInstance().mapSets = getSetMap(newList);
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
