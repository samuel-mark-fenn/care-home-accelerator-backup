import { LightningElement, track, wire } from "lwc";
import submitEnquiry from "@salesforce/apex/PublicEnquiryController.submitEnquiry";
import getProperties from "@salesforce/apex/PublicEnquiryController.getProperties";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class EnquiryForm extends LightningElement {
  @track formData = {
    enquiryType: "Looking for care for a loved one",
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    message: "",
    source: "",
    consent: false,
    admissionType: "",
    residentName: "",
    respiteStartDate: "",
    respiteEndDate: "",
    interests: "",
    interests: "",
    needs: "",
    careHomeId: ""
  };

  @track properties = [];
  @track isSubmitting = false;
  @track showThankYou = false;

  @wire(getProperties)
  wiredProperties({ error, data }) {
    if (data) {
      this.properties = data;
    } else if (error) {
      console.error("Error fetching properties:", error);
    }
  }

  get isLovedOne() {
    return this.formData.enquiryType === "Looking for care for a loved one";
  }

  get isRespite() {
    return this.formData.admissionType === "First Respite";
  }

  handleInputChange(event) {
    const field = event.target.name;
    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;
    this.formData = { ...this.formData, [field]: value };
  }

  handleNewEnquiry() {
    this.showThankYou = false;
    this.resetForm();
  }

  handleSubmit() {
    if (!this.validate()) {
      return;
    }

    this.isSubmitting = true;

    // Clean payload
    const payload = {
      firstName: this.formData.firstName,
      lastName: this.formData.lastName,
      email: this.formData.email,
      phone: this.formData.phone,
      enquiryType: this.formData.enquiryType,
      source: this.formData.source,
      message: this.formData.message,
      admissionType: this.formData.admissionType,
      residentName: this.isLovedOne ? this.formData.residentName : "",
      respiteStartDate: this.isRespite ? this.formData.respiteStartDate : null,
      respiteEndDate: this.isRespite ? this.formData.respiteEndDate : null,
      interests: this.isLovedOne ? this.formData.interests : "",
      needs: this.isLovedOne ? this.formData.needs : "",
      careHomeId: this.formData.careHomeId
    };

    submitEnquiry({ formData: payload })
      .then(() => {
        this.showThankYou = true;
        // Still show toast for screen readers/legacy support
        this.showToast("Success", "Your enquiry has been received.", "success");
      })
      .catch((error) => {
        this.showToast(
          "Error",
          error.body.message || "An error occurred",
          "error"
        );
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  resetForm() {
    this.formData = {
      enquiryType: "Looking for care for a loved one",
      firstName: "",
      lastName: "",
      email: "",
      phone: "",
      message: "",
      source: "",
      consent: false,
      admissionType: "",
      residentName: "",
      respiteStartDate: "",
      respiteEndDate: "",
      interests: "",
      interests: "",
      needs: "",
      careHomeId: ""
    };
    // Reset HTML inputs
    this.template
      .querySelectorAll("input, select, textarea")
      .forEach((input) => {
        if (input.type === "checkbox") input.checked = false;
        else input.value = "";
      });
  }

  validate() {
    let isValid = true;

    const inputs = this.template.querySelectorAll("input, select, textarea");
    inputs.forEach((input) => {
      if (input.required && !input.value) {
        input.classList.add("error");
        isValid = false;
      } else {
        input.classList.remove("error");
      }
    });

    if (!isValid) {
      this.showToast(
        "Required Fields",
        "Please fill in all required fields.",
        "warning"
      );
    }
    return isValid;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
