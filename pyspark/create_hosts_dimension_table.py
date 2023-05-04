from pyspark.sql import SparkSession

spark = SparkSession.builder.config(
    "temporaryGcsBucket", "dataproc-temp-bucket-2023"
).getOrCreate()

df = spark.read.format("bigquery").option("table", "raw_dataset.raw_data").load()

hosts = df.select(["year", "city"]).dropDuplicates()

hosts.write.format("bigquery").option(
    "table", "prod_dataset.hosts_dimension_table"
).mode("overwrite").save()
