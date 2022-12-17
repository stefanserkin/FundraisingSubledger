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
    @api futureAllocationSets;

    isLoading = false;
    error;

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

}