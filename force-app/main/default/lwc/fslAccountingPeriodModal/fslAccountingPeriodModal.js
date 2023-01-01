import { api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';

export default class FslAccountingPeriodModal extends LightningModal {
    @api header;
    @api content;
    @api postDate = new Date().toISOString().slice(0, 10);

    handlePostDateChange(event) {
        this.postDate = event.target.value;
    }

    handleConfirm() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);

        if (allValid) {
            this.close({
                isconfirm: true, 
                postdate: this.postDate
            });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Closed periods must have a post date',
                    message: 'Enter a post date before closing the period',
                    variant: 'error'
                })
            );
        }
    }

    handleCancel() {
        this.close({isconfirm: false});
    }
}