public without sharing class TA_Payment_CreateJournalEntriesAU implements TriggerAction.AfterUpdate {

    public void afterUpdate(
        List<npe01__OppPayment__c> newList, 
        List<npe01__OppPayment__c> oldList
    ) {
        Set<Id> setOppIds = new Set<Id>();
        for (npe01__OppPayment__c p : newList) setOppIds.add(p.npe01__Opportunity__c);
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
