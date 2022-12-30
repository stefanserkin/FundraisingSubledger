public class TA_JE_QueriesBI {

    private static TA_JE_QueriesBI instance;

    private TA_JE_QueriesBI() {}

    public static TA_JE_QueriesBI getInstance() {
        if (TA_JE_QueriesBI.instance == null) {
            TA_JE_QueriesBI.instance = new TA_JE_QueriesBI();
        }
        return TA_JE_QueriesBI.instance;
    }

    public Map<String, npsp__General_Accounting_Unit__c> mapGlCodeToGau { get; private set; }

    /*****************************************************
     * Called by metadata trigger handler
     * Manage from sObject Trigger Settings mdt: Journal Entry
     ******************************************************/

     public class Service implements TriggerAction.BeforeInsert {

        public void beforeInsert(List<Journal_Entry__c> newList) {
            TA_JE_QueriesBI.getInstance().mapGlCodeToGau = getMapGaus(newList);
        }

        private Map<String, npsp__General_Accounting_Unit__c> getMapGaus(
            List<Journal_Entry__c> newList
        ) {
            Map<String, npsp__General_Accounting_Unit__c> mapGaus = new Map<String, npsp__General_Accounting_Unit__c>();

            Set<String> setGlCodes = new Set<String>();
            for (Journal_Entry__c je : newList) setGlCodes.add(je.GL_Code__c);
            List<npsp__General_Accounting_Unit__c> lstGaus = [
                SELECT Id, Name, GL_Code__c
                  FROM npsp__General_Accounting_Unit__c
                 WHERE GL_Code__c IN :setGlCodes
                 LIMIT 10000
            ];
            for (npsp__General_Accounting_Unit__c gau : lstGaus) {
                mapGaus.put(gau.GL_Code__c, gau);
            }

            return mapGaus;
        }

    }
    
}
