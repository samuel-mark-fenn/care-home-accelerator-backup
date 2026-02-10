import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getResidents from '@salesforce/apex/AssessmentController.getResidents';
import getAssessmentTypes from '@salesforce/apex/AssessmentController.getAssessmentTypes';
import submitAssessment from '@salesforce/apex/AssessmentController.submitAssessment';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import RESIDENT_ASSESSMENT_OBJECT from '@salesforce/schema/Resident_Assessment__c';
import STATUS_FIELD from '@salesforce/schema/Resident_Assessment__c.Status__c';
import RISK_LEVEL_FIELD from '@salesforce/schema/Resident_Assessment__c.Risk_Level__c';
import OUTCOME_FIELD from '@salesforce/schema/Resident_Assessment__c.Overall_Outcome__c';
import OPPORTUNITY_RESIDENT_FIELD from '@salesforce/schema/Opportunity.Resident__c';

export default class MedicalAssessmentForm extends LightningElement {
    @api recordId; // Opportunity ID if on record page
    @track residentId;
    @track assessmentTypeId;
    @track assessmentDate;
    @track status = 'Scheduled';
    @track riskLevel;
    @track outcome;
    @track assessorId;
    
    // Assessment Fields
    @track medicalNeeds;
    @track mobility;
    @track nutrition;
    @track mentalHealth;
    @track personalCare;
    @track socialNeeds;
    @track followUpRequired = false;
    @track followUpNotes;

    @track residentOptions = [];
    @track typeOptions = [];
    @track statusOptions = [];
    @track riskOptions = [];
    @track outcomeOptions = [];

    // Wire Object Info for Picklists
    @wire(getObjectInfo, { objectApiName: RESIDENT_ASSESSMENT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STATUS_FIELD })
    wiredStatus({ error, data }) {
        if (data) this.statusOptions = data.values;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: RISK_LEVEL_FIELD })
    wiredStatusRisk({ error, data }) {
        if (data) this.riskOptions = data.values;
    }

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: OUTCOME_FIELD })
    wiredOutcome({ error, data }) {
        if (data) this.outcomeOptions = data.values;
    }

    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_RESIDENT_FIELD] })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.residentId = getFieldValue(data, OPPORTUNITY_RESIDENT_FIELD);
        }
    }

    // Wire Apex data
    @wire(getResidents)
    wiredResidents({ error, data }) {
        if (data) {
            this.residentOptions = data.map(res => ({ label: res.Name, value: res.Id }));
        }
    }

    @wire(getAssessmentTypes)
    wiredTypes({ error, data }) {
        if (data) {
            this.typeOptions = data.map(type => ({ label: type.Name, value: type.Id }));
        }
    }

    handleInputChange(event) {
        const fieldName = event.target.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

        if (fieldName === 'Resident__c') this.residentId = value;
        else if (fieldName === 'Assessment__c') this.assessmentTypeId = value;
        else if (fieldName === 'Assessment_Date__c') this.assessmentDate = value;
        else if (fieldName === 'Status__c') this.status = value;
        else if (fieldName === 'Risk_Level__c') this.riskLevel = value;
        else if (fieldName === 'Overall_Outcome__c') this.outcome = value;
        else if (fieldName === 'Medical_Needs_Assessment__c') this.medicalNeeds = value;
        else if (fieldName === 'Mobility_Assessment__c') this.mobility = value;
        else if (fieldName === 'Nutrition_Assessment__c') this.nutrition = value;
        else if (fieldName === 'Assessor__c') this.assessorId = value;
        else if (fieldName === 'Mental_Health_Assessment__c') this.mentalHealth = value;
        else if (fieldName === 'Personal_Care_Assessment__c') this.personalCare = value;
        else if (fieldName === 'Social_Needs_Assessment__c') this.socialNeeds = value;
        else if (fieldName === 'Follow_Up_Required__c') this.followUpRequired = value;
        else if (fieldName === 'Follow_Up_Notes__c') this.followUpNotes = value;
    }

    handleAssessorChange(event) {
        this.assessorId = event.detail.recordId;
    }

    handleSubmit() {
        if (!this.residentId || !this.assessmentTypeId) {
            this.showToast('Error', 'Please select a Resident and Assessment Type.', 'error');
            return;
        }

        const assessment = {
            sobjectType: 'Resident_Assessment__c',
            Resident__c: this.residentId,
            Assessment__c: this.assessmentTypeId,
            Assessment_Date__c: this.assessmentDate,
            Status__c: this.status,
            Risk_Level__c: this.riskLevel,
            Overall_Outcome__c: this.outcome,
            Medical_Needs_Assessment__c: this.medicalNeeds,
            Mobility_Assessment__c: this.mobility,
            Nutrition_Assessment__c: this.nutrition,
            Assessor__c: this.assessorId,
            Mental_Health_Assessment__c: this.mentalHealth,
            Personal_Care_Assessment__c: this.personalCare,
            Social_Needs_Assessment__c: this.socialNeeds,
            Follow_Up_Required__c: this.followUpRequired,
            Follow_Up_Notes__c: this.followUpNotes,
            Opportunity__c: this.recordId // Link to Opportunity if available
        };

        submitAssessment({ assessment })
            .then(() => {
                this.showToast('Success', 'Assessment created successfully.', 'success');
                // Reset form or navigate
                this.resetForm();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error(error);
            });
    }

    resetForm() {
        this.residentId = null;
        this.assessmentTypeId = null;
        this.assessmentDate = null;
        this.status = 'Scheduled';
        this.riskLevel = null;
        this.outcome = null;
        this.medicalNeeds = null;
        this.mobility = null;
        this.nutrition = null;
        this.assessorId = null;
        this.mentalHealth = null;
        this.personalCare = null;
        this.socialNeeds = null;
        this.followUpRequired = false;
        this.followUpNotes = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
