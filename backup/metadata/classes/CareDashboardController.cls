public with sharing class CareDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData() {
        DashboardData data = new DashboardData();
        
        // 1. Get Pipeline Data (Opportunity Stage counts)
        // We use StageName as the primary grouping
        List<AggregateResult> pipelineResults = [
            SELECT StageName, COUNT(Id) total
            FROM Opportunity
            WHERE IsClosed = false
            GROUP BY StageName
        ];
        
        for (AggregateResult ar : pipelineResults) {
            data.pipeline.add(new MetricItem(
                (String)ar.get('StageName'),
                (Integer)ar.get('total')
            ));
        }
        
        // 2. Get Occupancy Data (Room Status counts)
        List<AggregateResult> roomResults = [
            SELECT Availability_Status__c, COUNT(Id) total
            FROM Room__c
            GROUP BY Availability_Status__c
        ];
        
        Integer totalRooms = 0;
        Integer occupiedRooms = 0;
        
        for (AggregateResult ar : roomResults) {
            String status = (String)ar.get('Availability_Status__c');
            Integer count = (Integer)ar.get('total');
            
            if (String.isBlank(status)) status = 'Unknown';
            
            data.occupancy.add(new MetricItem(status, count));
            totalRooms += count;
            if (status == 'Occupied') {
                occupiedRooms += count;
            }
        }
        
        data.totalRooms = totalRooms;
        data.occupiedRooms = occupiedRooms;
        data.occupancyRate = totalRooms > 0 ? (Decimal.valueOf(occupiedRooms) / totalRooms * 100).setScale(1) : 0;
        
        return data;
    }
    
    public class DashboardData {
        @AuraEnabled public List<MetricItem> pipeline = new List<MetricItem>();
        @AuraEnabled public List<MetricItem> occupancy = new List<MetricItem>();
        @AuraEnabled public Integer totalRooms = 0;
        @AuraEnabled public Integer occupiedRooms = 0;
        @AuraEnabled public Decimal occupancyRate = 0;
    }
    
    public class MetricItem {
        @AuraEnabled public String label;
        @AuraEnabled public Integer value;
        
        public MetricItem(String label, Integer value) {
            this.label = label;
            this.value = value;
        }
    }
}