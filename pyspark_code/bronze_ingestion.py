# PySpark code for ingesting data from source to bronze layer

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, input_file_name

# Initialize Spark session
spark = SparkSession.builder.appName("ABC_Data_Ingestion").getOrCreate()

# Define storage account placeholder
storage_account = "your_storage_account_name"

# Define source paths
sales_orders_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order"
sales_org_plant_xref_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref"

# Ingest sales orders data to bronze layer
def ingest_sales_orders():
    # Read the CSV file
    df_sales_orders = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .csv(sales_orders_path)
    
    # Add source file information
    df_sales_orders = df_sales_orders \
        .withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_orders.write \
        .format("delta") \
        .mode("overwrite") \
        .saveAsTable("b_um_xyz.ABC_onetime_history_sales_orders")
    
    print("Sales orders data ingested successfully to bronze layer")

# Ingest sales org plant cross-reference data to bronze layer
def ingest_sales_org_plant_xref():
    # Read the CSV file
    df_sales_org_plant_xref = spark.read \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .csv(sales_org_plant_xref_path)
    
    # Add source file information
    df_sales_org_plant_xref = df_sales_org_plant_xref \
        .withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_org_plant_xref.write \
        .format("delta") \
        .mode("overwrite") \
        .saveAsTable("b_um_xyz.ABC_onetime_history_sales_org_plant_xref")
    
    print("Sales org plant cross-reference data ingested successfully to bronze layer")

# Execute ingestion functions
ingest_sales_orders()
ingest_sales_org_plant_xref()