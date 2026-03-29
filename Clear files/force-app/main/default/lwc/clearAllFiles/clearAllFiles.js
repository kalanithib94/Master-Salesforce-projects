import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from 'lightning/confirm';
import clearFiles from '@salesforce/apex/ClearRelatedFilesController.clearFiles';

export default class ClearAllFiles extends LightningElement {
    @api recordId;
    isWorking = false;

    async handleClearFiles() {
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to clear all attached files from this record?',
            variant: 'headerless',
            label: 'Confirm Clear Files'
        });

        if (!confirmed) {
            return;
        }

        this.isWorking = true;
        try {
            const removedCount = await clearFiles({ recordId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Completed',
                    message: `${removedCount} file link(s) removed.`,
                    variant: 'success'
                })
            );
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            const message = error?.body?.message || error?.message || 'Unable to clear files.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message,
                    variant: 'error'
                })
            );
        } finally {
            this.isWorking = false;
        }
    }
}
