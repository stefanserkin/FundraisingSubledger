public without sharing class TA_Payment_CreateJournalEntriesAD implements TriggerAction.AfterDelete {

    public void afterDelete(
        List<npe01__OppPayment__c> oldList
    ) {
        Set<Id> setOppIds = new Set<Id>();
        for (npe01__OppPayment__c p : oldList) setOppIds.add(p.npe01__Opportunity__c);
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
