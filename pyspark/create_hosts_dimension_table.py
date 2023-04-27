from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("HelloWorld").getOrCreate()
sc = spark.sparkContext
nums = sc.parallelize([1, 2, 3, 4])
print(nums.map(lambda x: x * x).collect())
