# PySpark code to extract data from gold view to CSV in outbound location

from pyspark.sql.functions import current_timestamp, date_format

# Define the outbound path
outbound_path = "/path/to/outbound/location"

# Read data from gold view
gold_df = spark.sql("SELECT * FROM g_onc.v_sales_ord_his")

# Generate a timestamp for the file name
timestamp = date_format(current_timestamp(), "yyyyMMdd_HHmmss")
output_file_path = f"{outbound_path}/sales_ord_his_{timestamp}.csv"

# Write to CSV in the outbound location
gold_df.coalesce(1).write.format("csv") \
    .option("header", "true") \
    .option("delimiter", ",") \
    .mode("overwrite") \
    .save(output_file_path)

print(f"Data exported to {output_file_path}")