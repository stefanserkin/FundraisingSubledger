public without sharing class TA_FA_CalculatePercentageBI implements TriggerAction.BeforeInsert {
    public void beforeInsert(List<Future_Allocation__c> newList) {
        Set<Id> setFasIds = new Set<Id>();
        for (Future_Allocation__c fa : newList) setFasIds.add(fa.Future_Allocation_Set__c);
        Map<Id, Future_Allocation_Set__c> mapSets = new Map<Id, Future_Allocation_Set__c>([
            SELECT Id, Opportunity__r.Amount
              FROM Future_Allocation_Set__c
             WHERE Id IN :setFasIds
        ]);
        for (Future_Allocation__c fa : newList) {
            fa.Amount__c = fa.Amount__c != null ? fa.Amount__c : 0;
            Decimal oppTotal = mapSets.get(fa.Future_Allocation_Set__c).Opportunity__r.Amount;
            fa.Percent__c = (fa.Amount__c / oppTotal) * 100;
        }
    }
}
