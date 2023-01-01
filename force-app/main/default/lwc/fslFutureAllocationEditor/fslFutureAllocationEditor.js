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
    @api futureAllocations;
    @track newFutureAllocations = [];
    passedAllocationSet;
    allocationDate;
    totalOpportunityAmount = 0;
    totalAllocated = 0;

    @api
    get allocationSet() {
        return this.passedAllocationSet;
    }
    set allocationSet(value) {
        this.totalAllocated = value.totalAllocated != null ? value.totalAllocated : 0;
        this.totalOpportunityAmount = value.Opportunity__r.Amount != null ? value.Opportunity__r.Amount : 0;
        this.allocationDate = value.Effective_Date__c != null ? value.Effective_Date__c : null;
        this.passedAllocationSet = value;
    }

    modalHeader = 'Manage Future Allocations';

    isLoading = false;
    error;

    isEditDate = false;
    
    futureAllocationObj = FUTURE_ALLOCATION_OBJECT;
    fields = [GAU_FIELD, FUTURE_SET_FIELD, AMOUNT_FIELD, PERCENT_FIELD];

    get allocationSetDateFormatted() {
        const dateOptions = {
            weekday: "long", year: "numeric", month: "long", day: "numeric", timeZone: 'UTC'
        };
        let dt = new Date( this.allocationDate );
        let formattedDate = new Intl.DateTimeFormat('en-US', dateOptions).format(dt);
        return formattedDate;
    }

    get totalAllocatedClass() {
        return this.totalAllocated > this.totalOpportunityAmount 
            ? 'slds-text-color_destructive' 
            : 'slds-text-color_default';
    }

    handleCloseEvent() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleRefreshData() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    handleEditDateToggle() {
        this.isEditDate = !this.isEditDate;
    }

    handleDateChange(event) {
        console.log(event.target.value);
        this.allocationDate = event.target.value;
        console.log(this.allocationDate);
    }

    handleAmountChange(event) {
        let total = 0;
        this.template.querySelectorAll("lightning-input-field.amount-field").forEach(field => {
            total += field.value != null ? Number(field.value) : 0;
        });
        this.totalAllocated = total;
    }

    handleUpdateDateSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The future allocation set date was updated',
                variant: 'success'
            })
        );
        this.handleRefreshData();
        this.handleEditDateToggle();
    }

    handleUpdateAllocationSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The future allocation details were updated',
                variant: 'success'
            })
        );
        this.handleRefreshData();
    }

    handleNewAllocationSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The new allocation was added',
                variant: 'success'
            })
        );
        this.handleRefreshData();
    }

    async handleDeleteRow(event) {
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
                    this.handleRefreshData();
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
            'Future_Allocation_Set__c': this.allocationSet.Id, 
            'General_Accounting_Unit__c': null, 
            'Amount__c': 0
        };
        let newArray = this.newFutureAllocations;
        newArray.push(newAlloc);
        this.newFutureAllocations = newArray;
    }

    handleCancelNewRow(event) {
        let index = event.target.dataset.index;
        console.log('index ' + index);
        console.table(this.newFutureAllocations);
        // Err.. still not working
        this.newFutureAllocations.splice(index, 1);
        console.table(this.newFutureAllocations);
    }

}
