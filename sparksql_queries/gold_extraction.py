# Gold Layer Data Extraction - PySpark Code

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from datetime import datetime
import os

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("Gold_Layer_Extraction") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()

# Define outbound path in ADLS
outbound_path = "/mnt/datalake/outbound/onc/sales_ord_his/"

def extract_gold_data_to_csv():
    try:
        # Read data from gold view
        gold_df = spark.sql("""
            SELECT 
                ApoPlanningVersion,
                ApmModelNumber,
                ProductPlannerCode,
                Country,
                SalesOffice,
                SalesOrganization,
                Plant,
                PlanningPartner,
                DistributionChannel,
                CustomerGroup,
                ShipToParty,
                SoldToParty,
                WwBusiness,
                StrategyCenter,
                ProductLine,
                PlanningSet,
                ProductSubset,
                ItemCategory,
                SalesDocumentType,
                SnapshotId,
                CalMonth,
                BaseUnitOfMeasure,
                SourceSystem,
                TotalDemandQuantityMts,
                TotalDemandSum,
                TotalReturnsQtyMts,
                RecordCount,
                LastProcessedTimestamp
            FROM g_onc.vw_sales_ord_his_summary
            ORDER BY CalMonth DESC, Country, SalesOrganization
        """)
        
        # Generate timestamp for file naming
        current_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # Coalesce to single partition for single CSV file
        gold_df_single = gold_df.coalesce(1)
        
        # Write to CSV in outbound location
        gold_df_single.write \
            .format("csv") \
            .mode("overwrite") \
            .option("header", "true") \
            .option("timestampFormat", "yyyy-MM-dd HH:mm:ss") \
            .save(f"{outbound_path}sales_ord_his_summary_{current_timestamp}")
        
        # Also create a detailed extract from silver layer
        silver_df = spark.sql("""
            SELECT 
                ApoPlanningVersion,
                ApmModelNumber,
                ProductPlannerCode,
                Country,
                SalesOffice,
                SalesOrganization,
                Plant,
                PlanningPartner,
                DistributionChannel,
                CustomerGroup,
                ShipToParty,
                SoldToParty,
                WwBusiness,
                StrategyCenter,
                ProductLine,
                PlanningSet,
                ProductSubset,
                ItemCategory,
                SalesDocumentType,
                SnapshotId,
                CalMonth,
                BaseUnitOfMeasure,
                SourceSystem,
                DemandQuantityMts,
                TotalDemand,
                ReturnsQtyMts,
                ProcessedTimestamp
            FROM s_onc.sales_ord_his
            WHERE CalMonth >= CAST(DATE_FORMAT(ADD_MONTHS(CURRENT_DATE(), -12), 'yyyyMM') AS INT)
            ORDER BY CalMonth DESC, Country, SalesOrganization
        """)
        
        # Write detailed data to CSV
        silver_df.coalesce(1).write \
            .format("csv") \
            .mode("overwrite") \
            .option("header", "true") \
            .option("timestampFormat", "yyyy-MM-dd HH:mm:ss") \
            .save(f"{outbound_path}sales_ord_his_detail_{current_timestamp}")
        
        print(f"Successfully extracted {gold_df.count()} summary records to CSV")
        print(f"Successfully extracted {silver_df.count()} detail records to CSV")
        print(f"Files saved to: {outbound_path}")
        
        return True
        
    except Exception as e:
        print(f"Error extracting gold data to CSV: {str(e)}")
        raise

# Execute extraction
if __name__ == "__main__":
    print("Starting Gold Layer Data Extraction...")
    
    # Extract data to CSV
    extract_gold_data_to_csv()
    
    print("Gold Layer Data Extraction Completed Successfully!")