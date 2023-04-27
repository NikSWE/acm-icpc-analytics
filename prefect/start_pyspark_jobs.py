import pandas as pd
from prefect import flow, task, get_run_logger
from prefect_gcp.cloud_storage import GcsBucket, GcpCredentials
from typing import List
import subprocess
import os


def spark_submit(file: str):
    return subprocess.run(
        [
            "gcloud",
            "dataproc",
            "jobs",
            "submit",
            "pyspark",
            file,
            f"--cluster={os.environ['CLUSTER']}",
            f"--region={os.environ['REGION']}",
            "--jars=gs://spark-lib/bigquery/spark-bigquery-latest.jar",
        ]
    )


@task(log_prints=True)
def create_hosts_dimension_table():
    logger = get_run_logger()
    res = spark_submit("create_hosts_dimension_table.py")
    logger.info(f"job status code: {res.returncode}")


@flow()
def start_pyspark_jobs() -> None:
    create_hosts_dimension_table()


if __name__ == "__main__":
    start_pyspark_jobs()
