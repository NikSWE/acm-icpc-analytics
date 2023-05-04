from pyspark.sql import SparkSession

spark = SparkSession.builder.config(
    "temporaryGcsBucket", "dataproc-temp-bucket-2023"
).getOrCreate()

df = spark.read.format("bigquery").option("table", "raw_dataset.raw_data").load()

countries = df.select(["year", "country"])

countries.write.format("bigquery").option(
    "table", "prod_dataset.countries_dimension_table"
).mode("overwrite").save()
