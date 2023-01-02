import { api, wire, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getGlAccounts from '@salesforce/apex/fsl_ManualAdjustmentController.getGlAccounts';
import createAdjustmentJournalEntries from '@salesforce/apex/fsl_ManualAdjustmentController.createAdjustmentJournalEntries';

import manualAdjustmentInstructionLabel from '@salesforce/label/c.fsl_Manual_Adjustment_Instructions';

export default class FslManualAdjustmentModal extends LightningModal {
    @api accountingPeriodId;
    error;
    isLoading = false;

    header = 'Manual Adjustment';

    manualAdjustmentInstructions = manualAdjustmentInstructionLabel;

    wiredGlAccounts = [];
    glAccounts;
    @track accountOptions = [];

    // Journal entry adjustment information
    jeDate = this.getDefaultDate();
    jeAmount = 0;
    jeDebitAccountId;
    jeCreditAccountId;
    jeNotes = '';

    getDefaultDate() {
        let effectiveDate = new Date();
        const offset = effectiveDate.getTimezoneOffset();
        effectiveDate = new Date(effectiveDate.getTime() - (offset*60*1000));
        return effectiveDate.toISOString().split('T')[0];
    }

    /**
     * Wire array of objects with gl id, name, and code
     */

    @wire(getGlAccounts)
    wiredResult(result) {
        this.isLoading = true;
        this.wiredGlAccounts = result;
        if (result.data) {
            this.glAccounts = result.data;
            let options = [];

            let rows = JSON.parse( JSON.stringify(result.data) );

            rows.forEach(row => {
                options.push({ label: row.label, value: row.id });
            });
            // Alphabetize by label
            options.sort(function(a, b) {
                const labelA = a.label.toUpperCase();
                const labelB = b.label.toUpperCase();
                if (labelA > labelB) {
                    return 1;
                } else if (labelA < labelB) {
                    return -1;
                } else {
                    return 0;
                }
            });

            this.accountOptions = options;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.glAccounts = undefined;
            this.error = result.error;
            console.error(this.error);
            this.isLoading = false;
        }
    }

    /**
     * Handle form actions
     */

    handleDebitAccountChange(event) {
        this.jeDebitAccountId = event.detail.value;
    }

    handleCreditAccountChange(event) {
        this.jeCreditAccountId = event.detail.value;
    }

    handleAmountChange(event) {
        this.jeAmount = event.detail.value;
    }

    handleDateChange(event) {
        this.jeDate = event.detail.value;
    }

    handleDescriptionChange(event) {
        this.jeNotes = event.detail.value;
    }

    handleSave() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (allValid) {
            this.isLoading = true;

            createAdjustmentJournalEntries({
                accountingPeriodId: this.accountingPeriodId, 
                jeDate: this.jeDate, 
                jeAmount: this.jeAmount, 
                jeDebitAccountId: this.jeDebitAccountId, 
                jeCreditAccountId: this.jeCreditAccountId, 
                jeNotes: this.jeNotes
            })
            .then(result => {
                console.log(result);
                this.isLoading = false;
                this.close(result);
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.close(this.error.body.message);
            });
        }
    }

    handleCancel() {
        this.close('Cancel');
    }

}