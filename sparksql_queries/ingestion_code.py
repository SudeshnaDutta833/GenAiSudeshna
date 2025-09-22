# PySpark code for ingesting data into bronze tables

from pyspark.sql.functions import input_file_name, current_timestamp

# Define paths for source data
sales_source_path = "/path/to/sales/data"
sales_org_source_path = "/path/to/sales_org/data"

# Ingest data into b_onc.Sales bronze table
def ingest_sales_data():
    # Read the source data
    sales_df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(sales_source_path)
    
    # Add source file information and ingest timestamp
    sales_df = sales_df.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    sales_df.write.format("delta") \
        .mode("append") \
        .saveAsTable("b_onc.Sales")
    
    print("Data ingested into b_onc.Sales successfully")

# Ingest data into b_onc.sales_org bronze table
def ingest_sales_org_data():
    # Read the source data
    sales_org_df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(sales_org_source_path)
    
    # Add source file information and ingest timestamp
    sales_org_df = sales_org_df.withColumn("SourceFile", input_file_name())
    
    # Write to bronze table
    sales_org_df.write.format("delta") \
        .mode("append") \
        .saveAsTable("b_onc.sales_org")
    
    print("Data ingested into b_onc.sales_org successfully")

# Execute the ingestion functions
ingest_sales_data()
ingest_sales_org_data()