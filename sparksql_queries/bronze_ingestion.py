# PySpark code for ingesting data from source to bronze tables

from pyspark.sql import SparkSession
from pyspark.sql.functions import input_file_name, current_timestamp

# Initialize Spark session
spark = SparkSession.builder.appName("ABC_Data_Ingestion").getOrCreate()

# Define storage account placeholder
storage_account = "your_storage_account_name"

# Define source and destination paths
sales_orders_source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order"
sales_org_plant_source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref"

# Ingest ABC sales orders data to bronze
def ingest_sales_orders():
    # Read the sales orders data
    df_sales_orders = spark.read.option("header", "true").option("inferSchema", "true").csv(sales_orders_source_path)
    
    # Add source file column
    df_sales_orders = df_sales_orders.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_orders.write.format("delta").mode("append").saveAsTable("b_um_xyz.ABC_onetime_history_sales_orders")
    
    print("Sales orders data ingested successfully to bronze layer")

# Ingest sales org plant cross reference data to bronze
def ingest_sales_org_plant():
    # Read the sales org plant data
    df_sales_org_plant = spark.read.option("header", "true").option("inferSchema", "true").csv(sales_org_plant_source_path)
    
    # Add source file column
    df_sales_org_plant = df_sales_org_plant.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_org_plant.write.format("delta").mode("append").saveAsTable("b_um_xyz.ABC_onetime_history_sales_org_plant_xref")
    
    print("Sales org plant cross reference data ingested successfully to bronze layer")

# Execute the ingestion functions
ingest_sales_orders()
ingest_sales_org_plant()