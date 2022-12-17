import { LightningElement, api, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getFutureAllocationSets from '@salesforce/apex/fsl_FutureAllocationManagerCtrl.getFutureAllocationSets';

import { loadStyle } from 'lightning/platformResourceLoader';
import modalStyle from '@salesforce/resourceUrl/modalWide';

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

    futureAllocationSets;
    wiredFutureAllocationSets = [];

    activeSections = [];
    activeSectionsMessage = '';

    showModal = false;
    modalEditMode = '';
    selectedSetId;

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
        this.selectedSetId = event.detail.recordId;
        this.modalEditMode = event.detail.value;
        console.log('::: selectedSetId: ' + this.selectedSetId);
        console.log('::: modalEditMode: ' + this.modalEditMode);
        this.showModal = true;
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
                console.log(':::::: total allocated for id ' + dataParse.Id + ': ' + totalAllocated);
                dataParse.newAllocations = [];
                dataParse.totalAllocated = totalAllocated;
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

    handleToggleModal() {
        this.showModal = !this.showModal;
    }

    handleManageAllocations() {
        this.showModal = true;
    }

    handleModalClose() {
        this.showModal = false;
    }

    handleRefreshData() {
        refreshApex(this.wiredFutureAllocationSets);
        console.log('refreshed apex');
    }

}