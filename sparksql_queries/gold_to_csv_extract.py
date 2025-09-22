# PySpark code for extracting data from gold view to CSV

from pyspark.sql import SparkSession

# Initialize Spark session
spark = SparkSession.builder.appName("Gold_To_CSV_Extract").getOrCreate()

# Define storage account placeholder
storage_account = "your_storage_account_name"

# Define output path
output_path = f"abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv"

# Read data from gold view
gold_df = spark.sql("SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history")

# Write to CSV
gold_df.coalesce(1).write \
    .option("header", "true") \
    .option("delimiter", ",") \
    .mode("overwrite") \
    .csv(output_path)

print(f"Data extracted successfully to {output_path}")