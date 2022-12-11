public without sharing class TA_Alloc_CreateJournalEntriesAI implements TriggerAction.AfterInsert {

    public void afterInsert(
        List<npsp__Allocation__c> newList
    ) {
        Set<Id> setOppIds = new Set<Id>();
        for (npsp__Allocation__c a : newList) setOppIds.add(a.npsp__Opportunity__c);
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
