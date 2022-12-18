public without sharing class TA_FALL_CalculatePercentBU implements TriggerAction.BeforeUpdate {

    private static Map<Id, Future_Allocation_Set__c> mapSets;

    public void beforeUpdate(List<Future_Allocation__c> newList, List<Future_Allocation__c> oldList) {
        mapSets = TA_FALL_QueriesBU.getInstance().mapSets;
        for (Future_Allocation__c fa : newList) {
            fa.Amount__c = fa.Amount__c != null ? fa.Amount__c : 0;
            Decimal oppTotal = mapSets.get(fa.Future_Allocation_Set__c).Opportunity__r.Amount;
            fa.Percent__c = (fa.Amount__c / oppTotal) * 100;
        }
    }
    
}
