import { LightningElement, wire, track } from "lwc";
import getDashboardData from "@salesforce/apex/CareDashboardController.getDashboardData";

export default class CareDashboard extends LightningElement {
  @track pipelineData = [];
  @track occupancyData = [];
  totalRooms = 0;
  occupiedRooms = 0;
  occupancyRate = 0;
  isLoading = true;

  @wire(getDashboardData)
  wiredData({ error, data }) {
    if (data) {
      this.processData(data);
      this.isLoading = false;
    } else if (error) {
      console.error("Error fetching dashboard data:", error);
      this.loadMockData();
      this.isLoading = false;
    }
  }

  processData(data) {
    // Process Pipeline
    const maxValue = Math.max(...data.pipeline.map((item) => item.value), 1);
    this.pipelineData = data.pipeline.map((item) => ({
      ...item,
      barStyle: `width: ${(item.value / maxValue) * 100}%;`
    }));

    this.occupancyData = data.occupancy;
    this.totalRooms = data.totalRooms;
    this.occupiedRooms = data.occupiedRooms;
    this.occupancyRate = data.occupancyRate;
  }

  loadMockData() {
    console.log("Loading mock data...");
    const mockData = {
      pipeline: [
        { label: "Prospecting", value: 12 },
        { label: "Qualification", value: 8 },
        { label: "Needs Analysis", value: 15 },
        { label: "Proposal", value: 5 },
        { label: "Negotiation", value: 3 }
      ],
      occupancy: [
        { label: "Occupied", value: 45 },
        { label: "Available", value: 5 },
        { label: "Maintenance", value: 2 }
      ],
      totalRooms: 52,
      occupiedRooms: 45,
      occupancyRate: 86.5
    };
    this.processData(mockData);
  }

  get availableRooms() {
    return this.totalRooms - this.occupiedRooms;
  }

  get occupancyDashArray() {
    return `${this.occupancyRate}, 100`;
  }

  get totalPipeline() {
    return this.pipelineData.reduce((sum, item) => sum + item.value, 0);
  }
}
