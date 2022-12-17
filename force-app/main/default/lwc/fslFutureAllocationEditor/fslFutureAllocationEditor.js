import { LightningElement, api, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import FUTURE_ALLOCATION_OBJECT from '@salesforce/schema/Future_Allocation__c';
import GAU_FIELD from '@salesforce/schema/Future_Allocation__c.General_Accounting_Unit__c';
import AMOUNT_FIELD from '@salesforce/schema/Future_Allocation__c.Amount__c';
import PERCENT_FIELD from '@salesforce/schema/Future_Allocation__c.Percent__c';

export default class FslFutureAllocationEditor extends LightningElement {
    @api opportunityId;
    @api allocationSetId;
    @api allocationSetDate;
    // @api futureAllocationSets;
    @api futureAllocations;
    @track newAllocationSets = [];

    isLoading = false;
    error;

    isEditDate = false;
    

    futureAllocationObj = FUTURE_ALLOCATION_OBJECT;
    gauField = GAU_FIELD;
    amountField = AMOUNT_FIELD;
    percentField = PERCENT_FIELD;

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

    /*

    handleAddNewSet() {
        let newSet = { 
            'sobjectType': 'Future_Allocation_Set__c', 
            'Opportunity__c': this.opportunityId, 
            'formattedName': `New Future Allocation Set`, 
            'isEditDate': true,
            'setIndex': this.newAllocationSets.length
        };
        console.log('::: newSet');
        console.log(newSet);
        console.log(':::: before adding to set: ' + this.hasNewAllocationSets);
        this.newAllocationSets.push(newSet);
        console.log(':::: after adding to set: ' + this.hasNewAllocationSets);
    }

    handleNewRow(event) {
        console.log('::::: handleNewRow with record id: ' + event.target.dataset.setId);
        const setId = event.target.dataset.setId;
        let newAlloc = { 'sobjectType': 'Future_Allocation__c' };
        newAlloc.Future_Allocation_Set__c = setId;
        newAlloc.General_Accounting_Unit__c = '';
        newAlloc.Amount__c = 0;
        console.log('::::: newAlloc has set id: ' + newAlloc.Future_Allocation_Set__c);
        this.futureAllocationSets.find(obj => obj.Id === setId).newAllocations.push(newAlloc);
    }

    */

}