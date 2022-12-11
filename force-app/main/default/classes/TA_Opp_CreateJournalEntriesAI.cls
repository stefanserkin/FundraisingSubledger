public with sharing class TA_Opp_CreateJournalEntriesAI implements TriggerAction.AfterInsert {

    /**
     * Managed in sObject Trigger Settings custom metadata (Opportunity)
     * Call journal entry service for opps in eligible accounting states
     */
    
    public void afterInsert(List<Opportunity> newList) {
        Map<String, String> mapStageToState = fsl_JournalEntryService.getStageToStateMappings();
        Set<Id> setOppIdsWithChanges = new Set<Id>();
        for (Opportunity opp : newList) {
            String oppStageName = mapStageToState.get(opp.StageName);
            if (
                oppStageName == fsl_JournalEntryService.ACCOUNTING_STATE_COMMITTED || 
                oppStageName == fsl_JournalEntryService.ACCOUNTING_STATE_FINALIZED
            ) {
                setOppIdsWithChanges.add(opp.Id);
            }
        }
        if (!setOppIdsWithChanges.isEmpty()) {
            try {
                fsl_JournalEntryService.createEntries(setOppIdsWithChanges);
            } catch (Exception e) {
                System.debug(':::: An error occurred: ' + e.getMessage());
            }
        }
    }

}
