public without sharing class TA_FALL_CalculatePercentBI implements TriggerAction.BeforeInsert {

    private static Map<Id, Future_Allocation_Set__c> mapSets;

    public void beforeInsert(List<Future_Allocation__c> newList) {
        mapSets = TA_FALL_QueriesBI.getInstance().mapSets;
        for (Future_Allocation__c fa : newList) {
            fa.Amount__c = fa.Amount__c != null ? fa.Amount__c : 0;
            Decimal oppTotal = mapSets.get(fa.Future_Allocation_Set__c).Opportunity__r.Amount;
            fa.Percent__c = (fa.Amount__c / oppTotal) * 100;
        }
    }

}
