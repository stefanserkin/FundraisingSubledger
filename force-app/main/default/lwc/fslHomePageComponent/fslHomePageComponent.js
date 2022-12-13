import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import runAccountingJob from '@salesforce/apex/fsl_HomePageComponentController.runAccountingJob';
import deleteAllData from '@salesforce/apex/fsl_HomePageComponentController.deleteAllData';

import USER_FIRSTNAME_FIELD from '@salesforce/schema/User.FirstName';
import USER_ID from '@salesforce/user/Id';

export default class FslHomePageComponent extends LightningElement {
    @api cardTitle;
    @api cardIcon;

    isLoading = false;
    error;

    userId = USER_ID;
    userFirstName;

    isAccountingJobConfig = false;
    mode = 'All';
    recordIds = null;
    startDate = null;
    endDate = null;

    get isModeAll() {
        return this.mode == 'All';
    }

    get isModeRecords() {
        return this.mode == 'Records';
    }

    get isModeDates() {
        return this.mode == 'Dates';
    }

    get modeOptions() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Record Ids', value: 'Records' },
            { label: 'Date Range', value: 'Dates' }
        ];
    }

    @wire(getRecord, { recordId: '$userId', fields: [ USER_FIRSTNAME_FIELD ]}) 
    userDetails({error, data}) {
        if (data) {
            this.userFirstName = data.fields.FirstName.value;
        } else if (error) {
            this.error = error ;
        }
    }

    get cardTitleAndUser() {
        return `${this.cardTitle}, ${this.userFirstName}!`;
    }

    get accountingJobToggleButtonLabel() {
        return !this.isAccountingJobConfig ? `Accounting Job` : `Hide Accounting Job`;
    }

    get accountingJobToggleButtonVariant() {
        return !this.isAccountingJobConfig ? `brand` : `brand-outline`;
    }

    handleModeChange(event) {
        this.mode = event.target.value;
    }

    handleRecordIdsChange(event) {
        this.recordIds = event.target.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleToggleAccountingJob() {
        this.isAccountingJobConfig = !this.isAccountingJobConfig;
    }

    handleRunAccountingJob() {
        this.isLoading = true;
        runAccountingJob({ mode: this.mode, recordIds: this.recordIds, startDate: this.startDate, endDate: this.endDate })
            .then(result => {
                this.strResult = result;
                if (result == 'Success') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'All journal entries were created',
                            variant: 'success'
                        })
                    );
                }
                this.isAccountingJobConfig = false;
                this.isLoading = true;
            })
            .catch(error => {
                console.error(error);
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Could not create journal entries. Received error: ' + this.error,
                        variant: 'error'
                    })
                );
                this.isAccountingJobConfig = false;
                this.isLoading = true;
            });
    }

    async handleDeleteAllData() {
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to reset all data? All opportunities, payments, allocations, and journal entries will be deleted',
            variant: 'header',
            label: 'Please Confirm',
            theme: 'error',
        });

        this.isLoading = true;
        if (!result) {
            this.isLoading = false;
        } else {
            deleteAllData()
                .then(result => {
                    this.strResult = result;
                    if (result == 'Success') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'All test data was removed from the database',
                                variant: 'success'
                            })
                        );
                        this.isLoading = false;
                    }
                })
                .catch(error => {
                    console.error(error);
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Could not remove test data. Received error: ' + this.error,
                            variant: 'error'
                        })
                    );
                    this.isLoading = false;
                });
        }
    }

}