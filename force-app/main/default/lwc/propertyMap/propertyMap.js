import { LightningElement, wire, track } from 'lwc';
import getProperties from '@salesforce/apex/PropertyMapController.getProperties';

export default class PropertyMap extends LightningElement {
    @track allProperties = [];
    @track filteredProperties = [];
    @track selectedCareTypes = ['Residential'];
    @track careTypeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Nursing', value: 'Nursing' },
        { label: 'Dementia', value: 'Dementia' },
        { label: 'Respite', value: 'Respite' }
    ];

    error;

    @wire(getProperties)
    wiredProperties({ error, data }) {
        if (data) {
            this.allProperties = data;
            this.applyFilters();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.allProperties = [];
        }
    }

    get mapMarkers() {
        return this.filteredProperties.map(prop => {
            return {
                location: {
                    PostalCode: prop.postcode,
                    Country: 'UK'
                },
                title: prop.name,
                description: `
                    <div style="font-family: 'Salesforce Sans', Arial, sans-serif;">
                        <p><strong>Manager:</strong> ${prop.managerName}</p>
                        <p><strong>Available Rooms:</strong> ${prop.availableRooms}</p>
                        <p><strong>Address:</strong> ${prop.postcode}</p>
                    </div>
                `,
                icon: 'standard:home'
            };
        });
    }

    handleFilterChange(event) {
        this.selectedCareTypes = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        if (this.selectedCareTypes.length === 0) {
            this.filteredProperties = [...this.allProperties];
        } else {
            this.filteredProperties = this.allProperties.filter(prop => {
                if (!prop.careTypes) return false;
                const propTypes = prop.careTypes.split(';');
                return this.selectedCareTypes.some(type => propTypes.includes(type));
            });
        }
    }
}
