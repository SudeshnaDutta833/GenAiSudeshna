# PySpark code for exporting gold view data to CSV in outbound location

from pyspark.sql.functions import current_timestamp, date_format

# Define the outbound path in ADLS
outbound_path = "/path/to/outbound/location"

# Read data from gold view
gold_view_df = spark.table("g_onc.v_sales_ord_his")

# Generate a timestamp for the file name
timestamp = date_format(current_timestamp(), "yyyyMMdd_HHmmss")
output_file_path = f"{outbound_path}/sales_ord_his_{timestamp}.csv"

# Write the data to CSV format
gold_view_df.write \
    .format("csv") \
    .option("header", "true") \
    .option("delimiter", ",") \
    .mode("overwrite") \
    .save(output_file_path)

print(f"Data exported successfully to {output_file_path}")