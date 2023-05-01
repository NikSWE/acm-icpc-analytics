import pandas as pd
from prefect import flow, task, get_run_logger
from prefect_gcp.cloud_storage import GcsBucket, GcpCredentials
from typing import List
import subprocess
import os


@task(log_prints=True)
def spark_submit(file: str):
    logger = get_run_logger()
    logger.info(f"Starting job: {file}")
    res = subprocess.run(
        [
            "gcloud",
            "dataproc",
            "jobs",
            "submit",
            "pyspark",
            file,
            f"--cluster={os.environ['CLUSTER']}",
            f"--region={os.environ['REGION']}",
        ]
    )
    logger.info(f"Job status code: {res.returncode}")


@flow()
def start_pyspark_jobs() -> None:
    jobs = [
        "create_hosts_dimension_table.py",
        "create_countries_dimension_table.py",
        "create_teams_dimension_table.py",
        "create_languages_dimension_table.py",
    ]
    for job in jobs:
        spark_submit(job)


if __name__ == "__main__":
    start_pyspark_jobs()
