import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import CloseModal from 'c/fslAccountingPeriodModal';
import AdjustmentModal from 'c/fslManualAdjustmentModal';
import LightningConfirm from 'lightning/confirm';
import unpostEntries from '@salesforce/apex/fsl_AccountingPeriodToolbarCtrl.unpostEntries';

import ID_FIELD from '@salesforce/schema/Accounting_Period__c.Id';
import NAME_FIELD from '@salesforce/schema/Accounting_Period__c.Name';
import STATUS_FIELD from '@salesforce/schema/Accounting_Period__c.Status__c';
import LAST_POST_DATE_FIELD from '@salesforce/schema/Accounting_Period__c.Last_Post_Date__c';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/Accounting_Period__c.Approval_Status__c';
import APPROVED_BY_FIELD from '@salesforce/schema/Accounting_Period__c.Approved_By__c';

import USER_ID from '@salesforce/user/Id';
import hasManageAccess from '@salesforce/customPermission/fsl_Manage_Accounting_Periods';

import CloseWarningLabel from '@salesforce/label/c.fsl_Accounting_Period_Close_Warning';
import ReopenWarningLabel from '@salesforce/label/c.fsl_Accounting_Period_Reopen_Warning';
import NoAccessHelpTextLabel from '@salesforce/label/c.fsl_Accounting_Period_No_Access_Help_Text';

export default class FslAccountingPeriodToolbar extends LightningElement {
    @api recordId;
    error;
    isLoading = false;

    userId = USER_ID;

    @track postDate;

    // Data returned by getRecord
    accountingPeriod;
    accountingPeriodName = '';
    currentStatus = '';
    lastPostDate;
    approvalStatus;
    approvedById;

    // Labels
    closePeriodLabel = 'Post Accounting Period';
    reopenPeriodLabel = 'Reopen Accounting Period';
    manualAdjustmentLabel = 'Manual Adjustment';

    get isToolbarDisabled() {
        return !hasManageAccess;
    }

    labels = {
        CloseWarningLabel, 
        ReopenWarningLabel, 
        NoAccessHelpTextLabel
    };

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [NAME_FIELD, STATUS_FIELD, LAST_POST_DATE_FIELD, APPROVAL_STATUS_FIELD, APPROVED_BY_FIELD] 
    })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading record',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            console.log(data);
            this.accountingPeriod = data;
            this.accountingPeriodName = this.accountingPeriod.fields.Name.value;
            this.currentStatus = this.accountingPeriod.fields.Status__c.value;
            this.lastPostDate = this.accountingPeriod.fields.Last_Post_Date__c.value;
            this.approvalStatus = this.accountingPeriod.fields.Approval_Status__c.value;
            this.approvedById = this.accountingPeriod.fields.Approved_By__c.value;
        }
    }

    get isClosed() {
        return this.currentStatus === 'Closed';
    }

    get closePeriodModalHeader() {
        return `Close ${this.accountingPeriodName}`;
    }

    /**
     * Open modal to force confirmation and collect close date
     */
    async handleClosePeriod() {
        const result = await CloseModal.open({
            size: 'small', 
            description: 'Close accounting period', 
            header: this.closePeriodModalHeader, 
            content: this.labels.CloseWarningLabel
        });
        if (result.isconfirm) {
            this.postDate = result.postdate;
            this.doClosePeriod();
        }
    }

    /**
     * Update accounting period status to closed
     */
    doClosePeriod() {
        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Closed';
        fields[LAST_POST_DATE_FIELD.fieldApiName] = this.postDate;
        if (this.approvalStatus != 'Approved') {
            fields[APPROVAL_STATUS_FIELD.fieldApiName] = 'Approved';
            fields[APPROVED_BY_FIELD.fieldApiName] = this.userId;
        }

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `${this.accountingPeriodName} has been closed.`,
                        variant: 'success'
                    })
                );
                eval("$A.get('e.force:refreshView').fire();");
                this.isLoading = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating accounting period',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    /**
     * Reopen a closed period
     */
    async handleReopenPeriod() {
        const userConfirmed = await LightningConfirm.open({
            message: this.labels.ReopenWarningLabel,
            variant: 'header',
            label: `Reopen ${this.accountingPeriodName}`,
            theme: 'alt-inverse'
        });

        if (!userConfirmed) return;

        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Open';
        fields[APPROVAL_STATUS_FIELD.fieldApiName] = null;
        fields[APPROVED_BY_FIELD.fieldApiName] = null;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `${this.accountingPeriodName} has been reopened.`,
                        variant: 'success'
                    })
                );
                this.isLoading = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating accounting period',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    /**
     * Manual adjustment
     * @returns void
     */
    async handleManualAdjustment() {
        const result = await AdjustmentModal.open({
            size: 'small', 
            description: 'Manual Adjustment', 
            accountingPeriodId: this.recordId
        });
        if (result === 'Success') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'The adjustment journal entries were successully created',
                    variant: 'success'
                })
            );
            eval("$A.get('e.force:refreshView').fire();");
        } else if (result != undefined && result != 'Cancel') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Could not create entries',
                    message: 'There was an error inserting journal entries: ' + result,
                    variant: 'error'
                })
            );
        }
    }

    /**
     * Unpost entries
     * @returns void
     */
    async handleUnpostEntries() {
        const userConfirmed = await LightningConfirm.open({
            message: `All journal entries for the ${this.accountingPeriodName} period will be unposted`, 
            variant: 'header',
            label: `Aaaaaaare you sure?`, 
            theme: 'alt-inverse'
        });

        if (!userConfirmed) return;

        this.isLoading = true;
        unpostEntries({recordId: this.recordId})
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'All journal entries for the period were unposted',
                        variant: 'success'
                    })
                );
                eval("$A.get('e.force:refreshView').fire();");
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }
    
}