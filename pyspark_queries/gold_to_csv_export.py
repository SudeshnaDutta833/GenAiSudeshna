# PySpark code for exporting gold view data to CSV

# Define storage account placeholder
storage_account = "your_storage_account"

# Export gold view data to CSV
def export_gold_view_to_csv():
    # Define target path for CSV export
    target_path = f"abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv"
    
    # Read data from gold view
    gold_df = spark.sql("SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history")
    
    # Write to CSV
    gold_df.coalesce(1).write.mode("overwrite").option("header", "true").csv(target_path)
    
    print(f"Gold view data exported successfully to CSV at {target_path}")

# Execute the export function
export_gold_view_to_csv()