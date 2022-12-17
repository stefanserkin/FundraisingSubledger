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
                         ORDER BY General_Accounting_Unit__c ASC)
                  FROM Future_Allocation_Set__c
                 WHERE Opportunity__c = :opportunityId
                  WITH SECURITY_ENFORCED
                 ORDER BY Effective_Date__c ASC
                 LIMIT 1000
            ];
            return lstSets;
        } catch (Exception e) {
            String errorMessage = 'The following exception has occurred: ' + e.getMessage();
            System.debug('::::: ' + errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }

    @AuraEnabled
    public static String createNewFutureSets(
        String opportunityId, 
        List<Date> lstDates
    ) {
        List<Future_Allocation_Set__c> lstToInsert = new List<Future_Allocation_Set__c>();
        for (Date d : lstDates) {
            lstToInsert.add(
                new Future_Allocation_Set__c(
                    Opportunity__c = opportunityId, 
                    Effective_Date__c = d
                )
            );
        }
        if (!lstToInsert.isEmpty()) insert lstToInsert;
        return 'Success';
    }

}
