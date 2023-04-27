from etl_gh_to_gcs import etl_parent_gh_to_gcs
from etl_gcs_to_gbq import etl_parent_gcs_to_gbq
from start_pyspark_jobs import start_pyspark_jobs
from prefect.deployments import Deployment
from typing import List

deployments: List[Deployment] = [
    Deployment.build_from_flow(
        flow=etl_parent_gh_to_gcs,
        name="etl_parent_gh_to_gcs",
        parameters={"years": list(range(1999, 2022))},
    ),
    Deployment.build_from_flow(
        flow=etl_parent_gcs_to_gbq,
        name="etl_parent_gcs_to_gbq",
        parameters={"years": list(range(1999, 2022))},
    ),
    Deployment.build_from_flow(
        flow=start_pyspark_jobs,
        name="start_pyspark_jobs",
    ),
]


if __name__ == "__main__":
    for deployment in deployments:
        deployment.apply()
