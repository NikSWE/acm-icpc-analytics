from pyspark.sql import SparkSession

spark = SparkSession.builder.config(
    "temporaryGcsBucket", "dataproc-temp-bucket-2023"
).getOrCreate()

df = spark.read.format("bigquery").option("table", "raw_dataset.raw_data").load()

teams = df.select(["year"])

teams.groupby("year").count().withColumnRenamed("count", "teams").write.format(
    "bigquery"
).option("table", "prod_dataset.teams_dimension_table").mode("overwrite").save()
