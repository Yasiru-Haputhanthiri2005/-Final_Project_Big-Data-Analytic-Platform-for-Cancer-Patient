from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, avg, stddev, count
import os
import pyodbc
import pandas as pd

# --- Initialize Spark Session ---
spark = SparkSession.builder \
    .appName("OralCancerAnomalyDetection") \
    .config("spark.sql.shuffle.partitions", "4") \
    .getOrCreate()

spark.sparkContext.setLogLevel("ERROR")
print("Spark Session Started Successfully")

# --- Load CSV Data ---
csv_path = r"C:\Users\User\Desktop\Computer Project\asia_oral_cancer_data.csv"

df = spark.read.csv(csv_path, header=True, inferSchema=True)
print(f"Data Loaded: {df.count()} records, {len(df.columns)} columns")

# --- Rename Columns ---
df = df.toDF(
    "ID", "Country", "Age", "Gender",
    "TobaccoUse", "AlcoholConsumption", "HPVInfection",
    "BetelQuidUse", "ChronicSunExposure", "PoorOralHygiene",
    "Diet", "FamilyHistory", "ImmuneSystem",
    "OralLesions", "UnexplainedBleeding", "DifficultySwallowing",
    "WhiteRedPatches", "TumorSize", "CancerStage",
    "TreatmentType", "SurvivalRate", "CostUSD",
    "EconomicBurden", "EarlyDiagnosis", "OralCancerDiagnosis"
)

# --- Basic Statistics ---
print("\nDataset Statistics:")
df.select("TumorSize", "SurvivalRate",
          "CostUSD", "Age").summary().show()

# --- Country Distribution ---
print("Records by Country:")
df.groupBy("Country").count() \
  .orderBy("count", ascending=False).show()

# ================================================
# ANOMALY DETECTION RULES
# ================================================

# --- Rule 1: Cancer Diagnosed but No Treatment ---
anomaly1 = df.filter(
    (col("OralCancerDiagnosis") == "Yes") &
    (col("TreatmentType") == "No Treatment")
).withColumn("AnomalyType",
    when(col("OralCancerDiagnosis") == "Yes",
         "Cancer Diagnosed but No Treatment"))

print(f"\nRule 1 - Cancer Diagnosed but No Treatment: "
      f"{anomaly1.count()} cases")

# --- Rule 2: Early Stage Low Survival ---
anomaly2 = df.filter(
    (col("CancerStage").isin([1, 2])) &
    (col("SurvivalRate") < 70)
).withColumn("AnomalyType",
    when(col("CancerStage").isin([1, 2]),
         "Early Stage with Low Survival Rate"))

print(f"Rule 2 - Early Stage Low Survival: "
      f"{anomaly2.count()} cases")

# --- Rule 3: No Treatment but High Cost ---
anomaly3 = df.filter(
    (col("TreatmentType") == "No Treatment") &
    (col("CostUSD") > 50000)
).withColumn("AnomalyType",
    when(col("TreatmentType") == "No Treatment",
         "No Treatment but High Cost"))

print(f"Rule 3 - No Treatment but High Cost: "
      f"{anomaly3.count()} cases")

# --- Rule 4: Stage 4 High Survival ---
anomaly4 = df.filter(
    (col("CancerStage") == 4) &
    (col("SurvivalRate") > 25)
).withColumn("AnomalyType",
    when(col("CancerStage") == 4,
         "Stage 4 with High Survival Rate"))

print(f"Rule 4 - Stage 4 High Survival: "
      f"{anomaly4.count()} cases")

# --- Rule 5: Statistical Cost Outlier (mean + 2*stddev) ---
cost_stats = df.select(
    avg("CostUSD").alias("mean"),
    stddev("CostUSD").alias("std")
).collect()[0]

mean_cost = cost_stats["mean"]
std_cost = cost_stats["std"]
cost_threshold = mean_cost + (2 * std_cost)

anomaly5 = df.filter(
    col("CostUSD") > cost_threshold
).withColumn("AnomalyType",
    when(col("CostUSD") > cost_threshold,
         "Statistical Cost Outlier"))

print(f"Rule 5 - Statistical Cost Outlier "
      f"(threshold=${cost_threshold:.2f}): {anomaly5.count()} cases")

# --- Rule 6: Young Patient with Advanced Cancer ---
anomaly6 = df.filter(
    (col("Age") < 30) &
    (col("CancerStage") >= 3)
).withColumn("AnomalyType",
    when(col("Age") < 30,
         "Young Patient with Advanced Cancer"))

print(f"Rule 6 - Young Patient Advanced Cancer: "
      f"{anomaly6.count()} cases")

# --- Rule 7: High Economic Burden with No Treatment ---
econ_stats = df.select(
    avg("EconomicBurden").alias("mean"),
    stddev("EconomicBurden").alias("std")
).collect()[0]

econ_threshold = econ_stats["mean"] + (2 * econ_stats["std"])

anomaly7 = df.filter(
    (col("TreatmentType") == "No Treatment") &
    (col("EconomicBurden") > econ_threshold)
).withColumn("AnomalyType",
    when(col("TreatmentType") == "No Treatment",
         "High Economic Burden with No Treatment"))

print(f"Rule 7 - High Economic Burden No Treatment "
      f"(threshold={econ_threshold:.0f} days): {anomaly7.count()} cases")

# ================================================
# COMBINE ALL ANOMALIES
# ================================================
all_anomalies = anomaly1 \
    .union(anomaly2) \
    .union(anomaly3) \
    .union(anomaly4) \
    .union(anomaly5) \
    .union(anomaly6) \
    .union(anomaly7)

total = all_anomalies.count()
print(f"\nTotal Anomalies Detected: {total}")

# --- Summary by Anomaly Type ---
print("\nAnomaly Summary by Type:")
all_anomalies.groupBy("AnomalyType") \
    .count() \
    .orderBy("count", ascending=False) \
    .show(truncate=False)

# --- Summary by Country ---
print("Anomalies by Country:")
all_anomalies.groupBy("Country", "AnomalyType") \
    .count() \
    .orderBy("count", ascending=False) \
    .show(truncate=False)

# --- Age Group Analysis ---
print("Anomalies by Age Group:")
all_anomalies.withColumn("AgeGroup",
    when(col("Age") < 30, "Under 30")
    .when((col("Age") >= 30) & (col("Age") < 45), "30-44")
    .when((col("Age") >= 45) & (col("Age") < 60), "45-59")
    .otherwise("60+")
).groupBy("AgeGroup", "AnomalyType") \
 .count() \
 .orderBy("AgeGroup") \
 .show(truncate=False)

# ================================================
# SAVE RESULTS TO CSV
# ================================================
output_path = r"C:\Users\User\Desktop\Computer Project\spark_anomaly_results.csv"

all_anomalies.select(
    "ID", "Country", "Age", "Gender",
    "CancerStage", "TumorSize", "SurvivalRate",
    "TreatmentType", "CostUSD", "EconomicBurden",
    "OralCancerDiagnosis", "EarlyDiagnosis", "AnomalyType"
).toPandas().to_csv(output_path, index=False)

print(f"\nResults saved to: {output_path}")

# ================================================
# LOAD RESULTS INTO SQL SERVER
# ================================================
print("\nLoading results into SQL Server DWH...")

try:
    df_results = pd.read_csv(output_path)

    conn = pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=DESKTOP-JTHSKFT\\SQLEXPRESS;"
        "DATABASE=OralcancerDWH;"
        "Trusted_Connection=yes;"
    )
    cursor = conn.cursor()

    # Clear previous Spark results
    cursor.execute("DELETE FROM SparkAnomalyResults")
    conn.commit()
    print("Previous results cleared")

    # Insert new results in batches
    batch_size = 500
    total_rows = len(df_results)
    inserted = 0

    for i in range(0, total_rows, batch_size):
        batch = df_results.iloc[i:i + batch_size]
        for _, row in batch.iterrows():
            cursor.execute("""
                INSERT INTO SparkAnomalyResults
                (PatientID, Country, Age, Gender, CancerStage,
                 TumorSize, SurvivalRate, TreatmentType, CostUSD,
                 EconomicBurden, OralCancerDiagnosis,
                 EarlyDiagnosis, AnomalyType)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            int(row['ID']),
            str(row['Country']),
            int(row['Age']),
            str(row['Gender']),
            int(row['CancerStage']),
            float(row['TumorSize']),
            float(row['SurvivalRate']),
            str(row['TreatmentType']),
            float(row['CostUSD']),
            int(row['EconomicBurden']),
            str(row['OralCancerDiagnosis']),
            str(row['EarlyDiagnosis']),
            str(row['AnomalyType'])
            )
        conn.commit()
        inserted += len(batch)
        print(f"Inserted {inserted}/{total_rows} records...")

    conn.close()
    print(f"{total_rows} anomaly records loaded into SQL Server!")

except Exception as e:
    print(f"SQL Server load failed: {e}")

# ================================================
# STOP SPARK
# ================================================
spark.stop()
print("Spark Session Stopped")
print("Pipeline Complete!")