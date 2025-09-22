# Bronze Layer Data Ingestion - PySpark Code

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
from datetime import datetime

# Initialize Spark Session
spark = SparkSession.builder \
    .appName("Bronze_Layer_Ingestion") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()

# Define source paths
sales_source_path = "/mnt/datalake/raw/onc/sales/"
sales_org_source_path = "/mnt/datalake/raw/onc/sales_org/"

# Define bronze table paths
sales_bronze_path = "/mnt/datalake/bronze/onc/sales/"
sales_org_bronze_path = "/mnt/datalake/bronze/onc/sales_org/"

# Sales table ingestion
def ingest_sales_data():
    try:
        # Read sales data from source
        sales_df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "false") \
            .csv(sales_source_path)
        
        # Add metadata columns
        sales_df_with_metadata = sales_df \
            .withColumn("SourceFile", input_file_name()) \
            .withColumn("LoadTimestamp", current_timestamp()) \
            .select(
                col("PRODUCT").alias("Product"),
                col("DMDUNIT").alias("DmdUnit"),
                col("DMDGROUP").alias("DmdGroup"),
                col("LOC").alias("Loc"),
                col("STARDATE").alias("StartDate"),
                col("DUR").alias("Dur"),
                col("TYPE").alias("Type"),
                col("EVENT").alias("Event"),
                col("QTY").cast("decimal(17,3)").alias("Qty"),
                col("HISTSTREAM").alias("HistStream"),
                col("SourceFile"),
                col("LoadTimestamp")
            )
        
        # Write to bronze layer
        sales_df_with_metadata.write \
            .format("delta") \
            .mode("append") \
            .option("mergeSchema", "true") \
            .save(sales_bronze_path)
        
        print(f"Successfully ingested {sales_df_with_metadata.count()} records to b_onc.sales")
        
    except Exception as e:
        print(f"Error ingesting sales data: {str(e)}")
        raise

# Sales Org table ingestion
def ingest_sales_org_data():
    try:
        # Read sales org data from source
        sales_org_df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "false") \
            .csv(sales_org_source_path)
        
        # Add metadata columns
        sales_org_df_with_metadata = sales_org_df \
            .withColumn("SourceFile", input_file_name()) \
            .withColumn("LoadTimestamp", current_timestamp()) \
            .select(
                col("LOC").alias("Loc"),
                col("Region").alias("Region"),
                col("Country").alias("Country"),
                col("Channel").alias("Channel"),
                col("Sales Org").alias("SalesOrg"),
                col("Plant/DC").alias("PlantDc"),
                col("SourceFile"),
                col("LoadTimestamp")
            )
        
        # Write to bronze layer
        sales_org_df_with_metadata.write \
            .format("delta") \
            .mode("append") \
            .option("mergeSchema", "true") \
            .save(sales_org_bronze_path)
        
        print(f"Successfully ingested {sales_org_df_with_metadata.count()} records to b_onc.sales_org")
        
    except Exception as e:
        print(f"Error ingesting sales org data: {str(e)}")
        raise

# Execute ingestion functions
if __name__ == "__main__":
    print("Starting Bronze Layer Data Ingestion...")
    
    # Ingest sales data
    ingest_sales_data()
    
    # Ingest sales org data
    ingest_sales_org_data()
    
    print("Bronze Layer Data Ingestion Completed Successfully!")

# Refresh bronze tables
spark.sql("REFRESH TABLE b_onc.sales")
spark.sql("REFRESH TABLE b_onc.sales_org")