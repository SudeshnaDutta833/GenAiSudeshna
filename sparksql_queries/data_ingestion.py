from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit

# create SparkSession
spark = SparkSession.builder.appName("Data Ingestion").getOrCreate()

# read data from source location
sales_df = spark.read.format("csv").option("header", "true").load("path_to_sales_data")
sales_org_df = spark.read.format("csv").option("header", "true").load("path_to_sales_org_data")

# add SourceFile column
sales_df = sales_df.withColumn("SourceFile", lit("sales_data.csv"))
sales_org_df = sales_org_df.withColumn("SourceFile", lit("sales_org_data.csv"))

# write data to bronze tables
sales_df.write.format("delta").mode("overwrite").saveAsTable("b_onc.sales")
sales_org_df.write.format("delta").mode("overwrite").saveAsTable("b_onc.sales_org")