public with sharing class fsl_FutureAllocationManagerCtrl {
    
    @AuraEnabled(cacheable=true)
    public static List<Future_Allocation_Set__c> getFutureAllocationSets(
        String opportunityId
    ) {
        try {
            List<Future_Allocation_Set__c> lstSets = new List<Future_Allocation_Set__c>();
            lstSets = [
                SELECT Id, 
                       Name, 
                       Effective_Date__c, 
                       (SELECT Id, 
                               Name, 
                               General_Accounting_Unit__c, 
                               General_Accounting_Unit__r.Name, 
                               General_Accounting_Unit__r.GL_Code__c, 
                               Amount__c, 
                               Percent__c
                          FROM Future_Allocations__r
                         ORDER BY Amount__c DESC)
                  FROM Future_Allocation_Set__c
                 WHERE Opportunity__c = :opportunityId
                  WITH SECURITY_ENFORCED
                 ORDER BY Effective_Date__c ASC
                 LIMIT 1000
            ];
            return lstSets;
        } catch (Exception e) {
            System.debug('::::: getFutureAllocationSets error: ' + e.getMessage());
        }
        return null;
    }

}
