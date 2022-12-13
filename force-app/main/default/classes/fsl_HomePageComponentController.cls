public with sharing class fsl_HomePageComponentController {

    @testVisible private static final String MODE_ALL = 'All';
    @testVisible private static final String MODE_RECORDS = 'Records';
    @testVisible private static final String MODE_DATES = 'Dates';

    /**
     * All mode
     */
    
    @AuraEnabled
    public static String runAccountingJob(
        String mode, 
        String recordIds, 
        Date startDate, 
        Date endDate
    ) {
        try {
            if (mode == MODE_ALL) {
                runInAllMode();
            }
            else if (mode == MODE_RECORDS) {
                runInRecordsMode(
                    mode, 
                    recordIds
                );
            }
            else if (mode == MODE_DATES) {
                runInDatesMode(
                    mode, 
                    startDate, 
                    endDate
                );
            }
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void runInAllMode() {
        List<Opportunity> lstOpps = [SELECT Id FROM Opportunity LIMIT 10000];
        Set<Id> setOppIds = new Set<Id>();
        for (Opportunity opp : lstOpps) setOppIds.add(opp.Id);
        fsl_JournalEntryService.createEntries(setOppIds);
    }

    /**
     * Records mode
     */

    private static void runInRecordsMode(
        String mode, 
        String recordIds
    ) {
        if (mode != MODE_RECORDS) throw new AuraHandledException('Incorrect parameters passed for mode');
        try {
            Set<Id> setOppIds = new Set<Id>();
            Set<String> setStrings = new Set<String>();
            setStrings.addAll(recordIds.split(','));
            for (String str : setStrings) setOppIds.add(Id.valueOf(str));
            fsl_JournalEntryService.createEntries(setOppIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Dates mode
     */

    private static void runInDatesMode(
        String mode, 
        Date startDate, 
        Date endDate
    ) {
        if (mode != MODE_DATES) throw new AuraHandledException('Incorrect parameters passed for mode');
        try {
            List<Opportunity> lstOpps = [
                SELECT Id 
                  FROM Opportunity 
                 WHERE CloseDate >= :startDate
                   AND CloseDate <= :endDate
                 LIMIT 10000
            ];
            Set<Id> setOppIds = new Set<Id>();
            for (Opportunity opp : lstOpps) setOppIds.add(opp.Id);
            fsl_JournalEntryService.createEntries(setOppIds);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String deleteAllData() {
        try {
            delete [SELECT Id FROM Journal_Entry__c];
            delete [SELECT Id FROM Opportunity];
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}
