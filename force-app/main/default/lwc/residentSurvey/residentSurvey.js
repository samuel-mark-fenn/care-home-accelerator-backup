import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInitialData from '@salesforce/apex/ResidentSurveyController.getInitialData';
import saveSurveyResponse from '@salesforce/apex/ResidentSurveyController.saveSurveyResponse';

export default class ResidentSurvey extends LightningElement {
    @api recordId; // Opportunity Id

    @track isLoading = true;
    @track isSubmitted = false;
    
    residentId;
    surveyId;

    // Form Data
    @track formData = {
        Food_Rating__c: null,
        Cleanliness_Rating__c: null,
        Staff_Rating__c: null,
        Activities_Rating__c: null,
        Overall_Rating__c: null,
        Comments__c: ''
    };

    ratingOptions = [
        { value: 1, label: '1' },
        { value: 2, label: '2' },
        { value: 3, label: '3' },
        { value: 4, label: '4' },
        { value: 5, label: '5' }
    ];

    connectedCallback() {
        this.fetchData();
    }

    async fetchData() {
        try {
            const data = await getInitialData({ opportunityId: this.recordId });
            if (data) {
                this.residentId = data.residentId;
                this.surveyId = data.surveyId;
            }
        } catch (error) {
            console.error('Error fetching data', error);
            this.showToast('Error', 'Could not load survey data', 'error');
        } finally {
            this.isLoading = false;
            this.updateRatingClasses();
        }
    }

    // Dynamic class calculation for rating buttons
    updateRatingClasses() {
        this.ratingOptions = this.ratingOptions.map(opt => {
            return {
                ...opt,
                foodClass: `rating-btn ${this.formData.Food_Rating__c === opt.value ? 'selected' : ''}`,
                cleanlinessClass: `rating-btn ${this.formData.Cleanliness_Rating__c === opt.value ? 'selected' : ''}`,
                staffClass: `rating-btn ${this.formData.Staff_Rating__c === opt.value ? 'selected' : ''}`,
                activitiesClass: `rating-btn ${this.formData.Activities_Rating__c === opt.value ? 'selected' : ''}`
            };
        });
    }

    handleRatingClick(event) {
        const field = event.target.dataset.field;
        const value = parseInt(event.target.dataset.value, 10);
        
        this.formData[field] = value;
        this.updateRatingClasses();
    }

    handleOverallChange(event) {
        this.formData.Overall_Rating__c = event.target.value;
    }

    handleCommentsChange(event) {
        this.formData.Comments__c = event.target.value;
    }

    async handleSubmit() {
        if (!this.isValid()) {
            this.showToast('Incomplete', 'Please fill in all ratings', 'warning');
            return;
        }

        this.isLoading = true;

        const responseRecord = {
            sobjectType: 'Survey_Response__c',
            Resident__c: this.residentId,
            Survey__c: this.surveyId,
            ...this.formData,
            Response_Date__c: new Date().toISOString().split('T')[0]
        };

        try {
            await saveSurveyResponse({ response: responseRecord });
            this.isSubmitted = true;
            this.showToast('Success', 'Survey submitted successfully!', 'success');
        } catch (error) {
            console.error('Error submitting survey', error);
            this.showToast('Error', 'Error submitting survey: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    isValid() {
        // Check if all rating fields are filled
        return this.formData.Food_Rating__c && 
               this.formData.Cleanliness_Rating__c && 
               this.formData.Staff_Rating__c && 
               this.formData.Activities_Rating__c && 
               this.formData.Overall_Rating__c;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
