public without sharing class TA_Alloc_CreateJournalEntriesAD implements TriggerAction.AfterDelete {

    public void afterDelete(
        List<npsp__Allocation__c> oldList
    ) {
        Set<Id> setOppIds = new Set<Id>();
        for (npsp__Allocation__c a : oldList) setOppIds.add(a.npsp__Opportunity__c);
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
