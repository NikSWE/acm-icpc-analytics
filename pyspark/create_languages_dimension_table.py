from pyspark.sql import SparkSession

spark = SparkSession.builder.config(
    "temporaryGcsBucket", "dataproc-temp-bucket-2023"
).getOrCreate()

df = spark.read.format("bigquery").option("table", "raw_dataset.raw_data").load()

languages = df.select(["year", "language"])

languages.write.format("bigquery").option(
    "table", "prod_dataset.languages_dimension_table"
).mode("overwrite").save()
