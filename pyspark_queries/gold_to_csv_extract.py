# PySpark code for extracting data from Gold view to CSV

from pyspark.sql.functions import current_timestamp

# Storage account details
storage_account = spark.conf.get("spark.storage.account")

# Define the target path for the CSV output
target_path = f"abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv"

# Read data from the gold view
gold_df = spark.table("g_external.v_sales_orders_demand_fcst_ABC_onetime_history")

# Write the data to CSV format
gold_df.write.format("csv") \
    .option("header", "true") \
    .option("delimiter", ",") \
    .mode("overwrite") \
    .save(target_path)

print(f"Data extracted successfully to {target_path}")