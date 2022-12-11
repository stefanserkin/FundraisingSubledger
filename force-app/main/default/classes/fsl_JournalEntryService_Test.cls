@isTest
private class fsl_JournalEntryService_Test {
    
    @isTest
    static void testGetOpenAccountingPeriod() {

    }

    @isTest
    static void testGetStageToStateMappings() {
        
    }

    @isTest
    static void testGetPaymentAccountMap() {
        
    }

    @isTest
    static void testGetDefaultReceivablesAccount() {
        String strReceivablesAccountName = fsl_JournalEntryService.RECEIVABLES_ACCOUNT_NAME;
        Global_GL_Account__mdt receivablesAccount = Global_GL_Account__mdt.getInstance(strReceivablesAccountName);
        Test.startTest();
        Global_GL_Account__mdt returnedAccount = fsl_JournalEntryService.getDefaultReceivablesAccount();
        Test.stopTest();
        System.assertEquals(returnedAccount.Id, receivablesAccount.Id);
    }

}
