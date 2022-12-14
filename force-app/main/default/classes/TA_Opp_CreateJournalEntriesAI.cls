public without sharing class TA_Opp_CreateJournalEntriesAI implements TriggerAction.AfterInsert {

    /**
     * Managed in sObject Trigger Settings custom metadata (Opportunity)
     * Call journal entry service for opps in eligible accounting states
     */
    
    public void afterInsert(
        List<Opportunity> newList
    ) {
        Map<String, String> mapStageToState = fsl_JournalEntryService.getStageToStateMappings();
        Set<Id> setOppIdsWithChanges = new Set<Id>();
        for (Opportunity opp : newList) {
            String strState = mapStageToState.get(opp.StageName);
            if (
                strState == fsl_JournalEntryService.ACCOUNTING_STATE_COMMITTED || 
                strState == fsl_JournalEntryService.ACCOUNTING_STATE_FINALIZED
            ) {
                setOppIdsWithChanges.add(opp.Id);
            }
        }
        if (!setOppIdsWithChanges.isEmpty()) {
            fsl_JournalEntryService.createEntries(setOppIdsWithChanges);
        }
    }

}
