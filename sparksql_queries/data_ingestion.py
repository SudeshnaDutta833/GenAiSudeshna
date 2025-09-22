# Ingest data into bronze tables
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("Data Ingestion").getOrCreate()

# Read data from source files
sales_df = spark.read.format("csv").option("header", "true").load("path_to_sales_data.csv")
sales_org_df = spark.read.format("csv").option("header", "true").load("path_to_sales_org_data.csv")

# Add SourceFile column
sales_df = sales_df.withColumn("SourceFile", spark._jsparkSession.sparkContext.getConf().get("spark.app.name"))
sales_org_df = sales_org_df.withColumn("SourceFile", spark._jsparkSession.sparkContext.getConf().get("spark.app.name"))

# Write data to bronze tables
sales_df.write.format("delta").mode("append").saveAsTable("b_onc.sales")
sales_org_df.write.format("delta").mode("append").saveAsTable("b_onc.sales_org")