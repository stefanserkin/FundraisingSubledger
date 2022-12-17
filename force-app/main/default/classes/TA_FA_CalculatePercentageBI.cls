public without sharing class TA_FA_CalculatePercentageBI implements TriggerAction.BeforeInsert {
    public void beforeInsert(List<Future_Allocation__c> newList) {
        Map<Id, Future_Allocation__c> mapAllocations = new Map<Id, Future_Allocation__c>([
            SELECT Id, Amount__c, Percent__c, Future_Allocation_Set__r.Opportunity__r.Amount
              FROM Future_Allocation__c
             WHERE Id IN :newList
        ]);
        for (Future_Allocation__c fa : newList) {
            Decimal oppTotal = mapAllocations.get(fa.Id).Future_Allocation_Set__r.Opportunity__r.Amount;
            fa.Percent__c = (fa.Amount__c / oppTotal) * 100;
        }
    }
}
