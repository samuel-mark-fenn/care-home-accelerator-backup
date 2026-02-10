import { LightningElement, api, wire, track } from 'lwc';
import startFinder from '@salesforce/apex/RoomFinderController.findRooms';
import confirmBooking from '@salesforce/apex/RoomFinderController.confirmBooking';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import RESIDENT_FIELD from '@salesforce/schema/Opportunity.Resident__c';
import START_DATE_FIELD from '@salesforce/schema/Opportunity.Respite_Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Opportunity.Respite_End_Date__c';

const FIELDS = [RESIDENT_FIELD, START_DATE_FIELD, END_DATE_FIELD];

export default class RoomFinder extends LightningElement {
    @api recordId; // Opportunity ID
    
    @track startDate;
    @track endDate;
    @track rooms = [];
    @track selectedRoom;
    @track finalPrice;
    
    isLoading = false;
    isStep1 = true;
    isStep2 = false;
    
    residentId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.residentId = getFieldValue(data, RESIDENT_FIELD);
            const startStr = getFieldValue(data, START_DATE_FIELD);
            const endStr = getFieldValue(data, END_DATE_FIELD);
            if (startStr) this.startDate = startStr;
            if (endStr) this.endDate = endStr;
        } else if (error) {
            console.error('Error loading opportunity', error);
        }
    }

    connectedCallback() {
        // Default start date to today if not yet set by wire
        if (!this.startDate) {
            this.startDate = new Date().toISOString().slice(0, 10);
        }
    }

    get noRooms() {
        return !this.isLoading && this.rooms.length === 0;
    }

    handleDateChange(event) {
        if (event.target.label === 'Start Date') {
            this.startDate = event.target.value;
        } else {
            this.endDate = event.target.value;
        }
    }

    handleFindRooms() {
        if (!this.startDate) {
            this.showToast('Error', 'Please select a start date', 'error');
            return;
        }
        if (!this.residentId) {
            this.showToast('Warning', 'No Resident linked to this Enquiry. Showing all available rooms.', 'warning');
            // proceed anyway? Or block?
            // proceed, but matching might return 0 matches for prefs.
        }

        this.isLoading = true;
        startFinder({ opportunityId: this.recordId, residentId: this.residentId, startDate: this.startDate })
            .then(result => {
                this.rooms = result.map(wrapper => {
                    return {
                        ...wrapper,
                        displayImage: wrapper.displayImageUrl,
                        // Add flat property for formatted currency if simple display needed, 
                        // though LWC handles currency formatting best with `lightning-formatted-number`.
                        Base_Weekly_Rate__c_Formatted: new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }).format(wrapper.room.Base_Weekly_Rate__c)
                    };
                });
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleSelectRoom(event) {
        const roomId = event.target.dataset.id;
        this.selectedRoom = this.rooms.find(r => r.room.Id === roomId);
        this.finalPrice = this.selectedRoom.room.Base_Weekly_Rate__c;
        this.isStep1 = false;
        this.isStep2 = true;
    }

    handlePriceChange(event) {
        this.finalPrice = event.target.value;
    }

    handleBack() {
        this.isStep2 = false;
        this.isStep1 = true;
    }

    handleConfirmBooking() {
        this.isLoading = true;
        confirmBooking({ 
            opportunityId: this.recordId, 
            roomId: this.selectedRoom.room.Id, 
            finalPrice: this.finalPrice,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(() => {
            this.showToast('Success', 'Booking Confirmed! Quote and Contract created.', 'success');
            this.isLoading = false;
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            // Optionally close screen action or navigate
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
