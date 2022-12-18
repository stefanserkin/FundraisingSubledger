import { LightningElement, api, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import FUTURE_ALLOCATION_OBJECT from '@salesforce/schema/Future_Allocation__c';
import GAU_FIELD from '@salesforce/schema/Future_Allocation__c.General_Accounting_Unit__c';
import FUTURE_SET_FIELD from '@salesforce/schema/Future_Allocation__c.Future_Allocation_Set__c';
import AMOUNT_FIELD from '@salesforce/schema/Future_Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Future_Allocation__c.Percent__c';

export default class FslFutureAllocationEditor extends LightningElement {
    @api opportunityId;
    @api allocationSetId;
    @api allocationSetDate;
    @api futureAllocations;
    @track newFutureAllocations = [];

    isLoading = false;
    error;

    isEditDate = false;
    
    futureAllocationObj = FUTURE_ALLOCATION_OBJECT;
    fields = [GAU_FIELD, FUTURE_SET_FIELD, AMOUNT_FIELD, PERCENT_FIELD];

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleRefreshApex() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    handleEditDateToggle() {
        this.isEditDate = !this.isEditDate;
    }

    handleDateChange(event) {
        this.allocationSetDate = event.target.value;
    }

    handleUpdateDate() {
        console.log(this.allocationSetDate);
        alert(`Updated date to ${this.allocationSetDate}! Just kidding. TODO`);
    }

    handleUpdateAllocationSuccess(event) {
        console.log('::: handle success for ' + event.detail.id);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The future allocation details were updated',
                variant: 'success'
            })
        );
        this.handleRefreshApex();
    }

    handleNewAllocationSuccess(event) {
        console.log('::: handle success for ' + event.detail.id);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The new allocation was added',
                variant: 'success'
            })
        );
        this.handleRefreshApex();
    }

    handleUpdateDateSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Date has been updated',
                variant: 'success'
            })
        );
        this.handleRefreshApex();
    }

    async handleDeleteRow(event) {
        console.log('::::: handleDeleteRow with record id: ' + event.target.dataset.recordId);
        const allocId = event.target.dataset.recordId;

        const result = await LightningConfirm.open({
            message: 'Click confirm to delete this future allocation',
            variant: 'header',
            label: 'Are You Sure?',
            theme: 'error',
        });

        if (result) {
            this.isLoading = true;
            deleteRecord(allocId)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Future allocation deleted',
                            variant: 'success'
                        })
                    );
                    this.handleRefreshApex();
                    this.isLoading = false;
                })
                .catch(error => {
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.isLoading = false;
                });
        }
    }

    handleNewRow() {
        let newAlloc = { 
            'sobjectType': 'Future_Allocation__c', 
            'Future_Allocation_Set__c': this.allocationSetId, 
            'General_Accounting_Unit__c': null, 
            'Amount__c': 0
        };
        console.log(newAlloc);
        let newArray = this.newFutureAllocations;
        newArray.push(newAlloc);
        this.newFutureAllocations = newArray;
        console.table(this.newFutureAllocations);
    }

    handleCancelNewRow(event) {
        let index = event.target.dataset.index;
        console.log('index ' + index);
        console.table(this.newFutureAllocations);
        // WHY DOESN'T THIS WORK? I DON'T THINK IT'S FINDING THE ITEM AT ALL
        // BUT STILL REMOVES THE LAST ITEM IN THE ARRAY
        this.newFutureAllocations.splice(index, 1);
        console.table(this.newFutureAllocations);
    }

}