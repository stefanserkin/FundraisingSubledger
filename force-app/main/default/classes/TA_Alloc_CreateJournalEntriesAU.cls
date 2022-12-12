public without sharing class TA_Alloc_CreateJournalEntriesAU implements TriggerAction.AfterUpdate {

    public void afterUpdate(
        List<npsp__Allocation__c> newList, 
        List<npsp__Allocation__c> oldList
    ) {
        System.debug(':::: entered allocation after update');
        Set<Id> setOppIds = new Set<Id>();
        for (npsp__Allocation__c a : newList) setOppIds.add(a.npsp__Opportunity__c);
        System.debug(':::: amount of opps to create jes for : ' + setOppIds.size());
        if (!setOppIds.isEmpty()) fsl_JournalEntryService.createEntries(setOppIds);
    }
    
}
