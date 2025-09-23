# PySpark code for ingesting data into Bronze tables

# Import necessary libraries
from pyspark.sql.functions import current_timestamp, input_file_name

# Define storage account placeholder
storage_account = "your_storage_account"

# Ingest ABC_sales_order data to bronze layer
def ingest_sales_orders_to_bronze():
    # Define source path
    source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order"
    
    # Read the data
    df_sales_orders = spark.read.option("header", "true").option("inferSchema", "true").csv(source_path)
    
    # Add source file tracking
    df_sales_orders = df_sales_orders.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_orders.write.format("delta").mode("overwrite").saveAsTable("b_um_xyz.ABC_onetime_history_sales_orders")
    
    print("Sales orders data ingested successfully to bronze layer")

# Ingest ABC_sales_org_plant_xref data to bronze layer
def ingest_sales_org_plant_xref_to_bronze():
    # Define source path
    source_path = f"abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref"
    
    # Read the data
    df_sales_org_plant_xref = spark.read.option("header", "true").option("inferSchema", "true").csv(source_path)
    
    # Add source file tracking
    df_sales_org_plant_xref = df_sales_org_plant_xref.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df_sales_org_plant_xref.write.format("delta").mode("overwrite").saveAsTable("b_um_xyz.ABC_onetime_history_sales_org_plant_xref")
    
    print("Sales org plant xref data ingested successfully to bronze layer")

# Execute the ingestion functions
ingest_sales_orders_to_bronze()
ingest_sales_org_plant_xref_to_bronze()