public with sharing class TA_Opp_HandleCommitmentBI implements TriggerAction.BeforeInsert {

    public void beforeInsert(List<Opportunity> newList) {
        Map<String, String> mapStageToState = fsl_JournalEntryService.getStageToStateMappings();
        for (Opportunity opp : newList) {
            if (
                mapStageToState.get(opp.StageName) == fsl_Constants.ACCOUNTING_STATE_COMMITTED || 
                mapStageToState.get(opp.StageName) == fsl_Constants.ACCOUNTING_STATE_FINALIZED 
            ) {
                opp.Committed_Date__c = opp.CloseDate <= System.today() ? opp.CloseDate : System.today();
            }
        }
    }
    
}
