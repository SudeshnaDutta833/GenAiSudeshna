# PySpark code for ingesting data into Bronze tables

from pyspark.sql.functions import input_file_name, current_timestamp, lit

# Storage account details
storage_account = spark.conf.get("spark.storage.account")

# Ingest ABC sales order history data
def ingest_sales_order_history():
    # Define the source path
    source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order"
    
    # Read the data
    df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(source_path)
    
    # Add source file information
    df = df.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable("b_um_xyz.ABC_onetime_history_sales_orders")
    
    print("Sales order history data ingested successfully")

# Ingest sales org plant cross-reference data
def ingest_sales_org_plant_xref():
    # Define the source path
    source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref"
    
    # Read the data
    df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(source_path)
    
    # Add source file information
    df = df.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable("b_um_xyz.ABC_onetime_history_sales_org_plant_xref")
    
    print("Sales org plant cross-reference data ingested successfully")

# Execute the ingestion functions
ingest_sales_order_history()
ingest_sales_org_plant_xref()