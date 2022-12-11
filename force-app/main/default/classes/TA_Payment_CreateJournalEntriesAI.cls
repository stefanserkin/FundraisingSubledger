public without sharing class TA_Payment_CreateJournalEntriesAI implements TriggerAction.AfterInsert {

    public void afterInsert(
        List<npe01__OppPayment__c> newList
    ) {
        Set<Id> setOppIds = new Set<Id>();
        for (npe01__OppPayment__c p : newList) setOppIds.add(p.npe01__Opportunity__c);
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
