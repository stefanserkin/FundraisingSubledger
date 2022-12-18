import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { createRecord } from 'lightning/uiRecordApi';
import getFutureAllocationSets from '@salesforce/apex/fsl_FutureAllocationManagerCtrl.getFutureAllocationSets';
// import createNewFutureSets from '@salesforce/apex/fsl_FutureAllocationManagerCtrl.createNewFutureSets';

import { loadStyle } from 'lightning/platformResourceLoader';
import modalStyle from '@salesforce/resourceUrl/modalWide';

import FUTURE_SET_OBJECT from '@salesforce/schema/Future_Allocation_Set__c';
import OPPORTUNITY_FIELD from '@salesforce/schema/Future_Allocation_Set__c.Opportunity__c';
import DATE_FIELD from '@salesforce/schema/Future_Allocation_Set__c.Effective_Date__c';

const COLS = [
    { label: 'Name', fieldName: 'Name', type: 'text', hideDefaultActions: true }, 
    { label: 'GL Name', fieldName: 'glName', type: 'text', hideDefaultActions: true }, 
    { label: 'GL Code', fieldName: 'glCode', type: 'text', hideDefaultActions: true }, 
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency', wrapText: true, hideDefaultActions: true, 
        typeAttributes: { 
            currencyCode: 'USD', 
            minimumFractionDigits: 0, 
            maximumFractionDigits: 2 
        } 
    }, 
    { label: 'Percent', fieldName: 'percent', type: 'percent', hideDefaultActions: true, 
        typeAttributes: {
            minimumFractionDigits: 0, 
            maximumFractionDigits: 2 
        }
    }
];

export default class FslFutureAllocationManager extends LightningElement {
    @api recordId;

    isLoading = false;
    error;

    cols = COLS;

    cardTitle = 'Manage Future Allocations';
    cardIcon = 'custom:custom30';

    @track futureAllocationSets;
    wiredFutureAllocationSets = [];

    activeSections = [];
    activeSectionsMessage = '';

    showModal = false;
    selectedSetId;
    selectedSetDate;
    selectedSetAllocations = [];

    isAddingFutureSet = false;
    dateInput;

    // Load wide modal css from static resource
	connectedCallback() {
		Promise.all([
			 loadStyle(this, modalStyle)
		]);
	}

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage =
                'Open sections: ' + openSections.join(', ');
        }
    }

    handleMenuSelect(event) {
        const menuAction = event.detail.value;
        this.selectedSetId = event.currentTarget.dataset.recordId;
        console.log('::: selectedSetId: ' + this.selectedSetId);
        let selectedSet = this.futureAllocationSets.find(selSet => selSet.Id === this.selectedSetId);
        console.log(selectedSet);
        console.log(selectedSet.Effective_Date__c);
        this.selectedSetDate = selectedSet.Effective_Date__c;
        this.selectedSetAllocations = selectedSet.Future_Allocations__r;
        console.log('::: selectedSetAllocations: ' + this.selectedSetAllocations);
        if (menuAction === 'edit') {
            this.showModal = true;
        } else if (menuAction === 'delete') {
            alert('TODO - use lightning confirm and delete set with all child allocations');
        }
    }

    @wire(getFutureAllocationSets, {opportunityId: '$recordId'})
    wiredResult(result) {
        this.isLoading = true;
        this.wiredFutureAllocationSets = result;
        if (result.data) {

            const dateOptions = {
                weekday: "long", year: "numeric", month: "long", day: "numeric", timeZone: 'UTC'
            };

            console.log(':::: received data from controller');
            console.table(result.data);

            let rows = JSON.parse( JSON.stringify(result.data) );
            rows.forEach(dataParse => {
                console.log(':::: set id: ' + dataParse.Id);
                let totalAllocated = 0;
                let dt = new Date( dataParse.Effective_Date__c );
                let formattedDate = new Intl.DateTimeFormat('en-US', dateOptions).format(dt);
                dataParse.formattedDate = formattedDate;
                dataParse.formattedName = `${formattedDate} (${dataParse.Name})`;
                dataParse.hasAllocations = dataParse.Future_Allocations__r != null && dataParse.Future_Allocations__r.length > 0 ? true : false;
                console.log('::::: has allocations: ' + dataParse.hasAllocations);
                if (dataParse.hasAllocations) {
                    dataParse.Future_Allocations__r.forEach(alloc => {
                        alloc.glName = alloc.General_Accounting_Unit__r.Name;
                        alloc.glCode = alloc.General_Accounting_Unit__r.GL_Code__c;
                        alloc.percent = alloc.Percent__c != null ? alloc.Percent__c / 100 : 0;
                        totalAllocated += alloc.Amount__c != null ? alloc.Amount__c : 0;
                    });
                }
                dataParse.totalAllocated = totalAllocated;
                console.log(':::::: total allocated for id ' + dataParse.Id + ': ' + totalAllocated);
            });
            this.futureAllocationSets = rows;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            console.error(result.error);
            this.error = result.error;
            this.futureAllocationSets = undefined;
            this.isLoading = false;
        }
    }
    
    
    handleNewFutureSet() {
        /*
        console.log('Adding new future set');
        let newSet = {
            'sobjectType': 'Future_Allocation_Set__c', 
            'Opportunity__c': this.recordId
        }
        console.log(newSet.Opportunity__c);
        this.newFutureSets.push(newSet);
        */
        this.isAddingFutureSet = !this.isAddingFutureSet;
    }

    /*
    handleNewFutureSetSuccess(event) {
        console.log('Saving new future set');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'The future allocation set was created',
                variant: 'success'
            })
        );
        this.handleRefreshData();
        this.isAddingFutureSet = this.newFutureSets != null & this.newFutureSets.length > 0 ? true : false;
    }
    */

    handleCancelNewRow() {
        this.isAddingFutureSet = false;
    }

    handleToggleModal() {
        this.handleRefreshData();
        this.showModal = !this.showModal;
    }

    handleRefreshData() {
        refreshApex(this.wiredFutureAllocationSets);
        console.log('refreshed apex');
    }


    /************************************************
     * Handle newly added future allocation sets
     ************************************************/

    handleCancel() {
        this.isAddingFutureSet = false;
    }

    handleFieldChange(event) {
        console.log('Field has changed');
        this.dateInput = event.target.value;
    }

    handleSubmit() {

        const fields = {};
        fields[OPPORTUNITY_FIELD.fieldApiName] = this.recordId;
        fields[DATE_FIELD.fieldApiName] = this.dateInput;
        const recordInput = { 
            apiName: FUTURE_SET_OBJECT.objectApiName, 
            fields 
        };

        createRecord(recordInput)
            .then(result => {
                console.log(result);
                this.handleRefreshData();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'The new future allocation set was created',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to create future allocation set: ' + error.message,
                        variant: 'error'
                    })
                );
            })

    }

}