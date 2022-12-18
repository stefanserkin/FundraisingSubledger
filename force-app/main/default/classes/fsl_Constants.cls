public without sharing class fsl_Constants {
    
    /******************************
     * Statuses
     ******************************/

    @testVisible 
    static final String AP_STATUS_CLOSED = 'Closed';
    @testVisible 
    static final String JE_STATUS_POSTED = 'Posted';
    @testVisible 
    static final String JE_STATUS_DENIED = 'Denied';
    @testVisible
    static final String ACCOUNTING_STATE_UNCOMMITTED = 'Uncommitted';
    @testVisible
    static final String ACCOUNTING_STATE_COMMITTED = 'Committed';
    @testVisible
    static final String ACCOUNTING_STATE_FINALIZED = 'Finalized';

    /******************************
     * Labels
     ******************************/

    @testVisible
    static final String RECEIVABLES_ACCOUNT_NAME = 'Pledges_Receivable';
    @testVisible
    static final String GLOBAL_GL_TYPE_RECEIVABLES = 'Receivables';
    @testVisible
    static final String GLOBAL_GL_TYPE_PAYMENT = 'Payment';
    @testVisible
    static final String DEBIT_LABEL = 'Debit';
    @testVisible
    static final String CREDIT_LABEL = 'Credit';

    /******************************
     * Accounting Job Modes
     ******************************/

     @testVisible
     static final String ACCOUNTING_JOB_MODE_ALL = 'All';
     @testVisible
     static final String ACCOUNTING_JOB_MODE_RECORDS = 'Records';
     @testVisible
     static final String ACCOUNTING_JOB_MODE_DATES = 'Dates';

}
