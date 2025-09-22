# PySpark code for data ingestion from source to bronze tables

from pyspark.sql import SparkSession
from pyspark.sql.functions import input_file_name, current_timestamp

# Initialize Spark Session
spark = SparkSession.builder.appName("Bronze Layer Ingestion").getOrCreate()

# Define source and target locations
sales_source_path = "/path/to/sales/data"  # Replace with actual source path
sales_org_source_path = "/path/to/sales_org/data"  # Replace with actual source path
outbound_path = "/path/to/outbound/location"  # Replace with actual outbound path

# Function to ingest data into bronze layer with source file tracking
def ingest_to_bronze(source_path, target_table, format_type="csv"):
    """
    Ingest data from source location to bronze table
    
    Args:
        source_path: Source file or directory path
        target_table: Fully qualified target table name
        format_type: Source file format (default: csv)
    """
    print(f"Ingesting data from {source_path} to {target_table}")
    
    # Read data from source
    df = spark.read.format(format_type) \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(source_path)
    
    # Add source file tracking column
    df = df.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    df.write.format("delta") \
        .mode("overwrite") \
        .saveAsTable(target_table)
    
    print(f"Successfully ingested data into {target_table}")

# Ingest sales data
ingest_to_bronze(sales_source_path, "b_onc.sales")

# Ingest sales org data
ingest_to_bronze(sales_org_source_path, "b_onc.sales_org")

# Function to export data from gold view to CSV
def export_to_csv(source_view, target_path):
    """
    Export data from gold view to CSV in outbound location
    
    Args:
        source_view: Source view name
        target_path: Target path for CSV export
    """
    print(f"Exporting data from {source_view} to {target_path}")
    
    # Read from gold view
    df = spark.table(source_view)
    
    # Write to CSV
    df.write.format("csv") \
        .option("header", "true") \
        .mode("overwrite") \
        .save(target_path)
    
    print(f"Successfully exported data to {target_path}")

# Export gold view to CSV
export_to_csv("g_onc.sales_order_history_view", f"{outbound_path}/sales_order_history")

print("Data ingestion and export process completed successfully")