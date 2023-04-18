from ingest_from_kaggle import etl_kaggle_to_gcs
from prefect.deployments import Deployment

deployment = Deployment.build_from_flow(
    flow=etl_kaggle_to_gcs,
    name="etl_kaggle_to_gcs",
)

if __name__ == "__main__":
    deployment.apply()
