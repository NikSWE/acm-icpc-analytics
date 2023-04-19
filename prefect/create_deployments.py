from etl_gh_to_gcs import etl_parent_gh_to_gcs
from prefect.deployments import Deployment

deployment = Deployment.build_from_flow(
    flow=etl_parent_gh_to_gcs,
    name="etl_parent_gh_to_gcs",
    parameters={"years": list(range(1999, 2022))},
)

if __name__ == "__main__":
    deployment.apply()
