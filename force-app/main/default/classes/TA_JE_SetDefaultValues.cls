public without sharing class TA_JE_SetDefaultValues implements TriggerAction.BeforeInsert {

    // From original context query - all GAUs by gl code
    private static Map<String, npsp__General_Accounting_Unit__c> mapGlCodeToGau;

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Journal Entry
     ******************************************************/
    
    public void beforeInsert(
        List<Journal_Entry__c> newList
    ) {
        mapGlCodeToGau = TA_JE_QueriesBI.getInstance().mapGlCodeToGau;
        for (Journal_Entry__c je : newList) {
            if (mapGlCodeToGau.containsKey(je.GL_Code__c)) {
                je.General_Accounting_Unit__c = mapGlCodeToGau.get(je.GL_Code__c).Id;
            }
        }
    }

}
