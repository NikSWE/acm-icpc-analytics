import pandas as pd
from prefect import flow, task, get_run_logger
from pathlib import Path
from prefect_gcp.cloud_storage import GcsBucket
from typing import List
import os


@task(
    description="fetch the dataset for the year provided from github",
    log_prints=True,
    retries=5,
)
def fetch_dataset(year: int) -> pd.DataFrame:
    logger = get_run_logger()
    gh_url = "https://raw.githubusercontent.com/duty-bois/icpc-kaggle-dataset/main"
    df = pd.read_csv(f"{gh_url}/icpc-{year}.csv")
    logger.info(f"Successfully downloaded icpc-{year}.csv dataset")
    return df


@task(description="transform the column headers to lowercase", log_prints=True)
def transform_headers_to_lowercase(df: pd.DataFrame) -> pd.DataFrame:
    logger = get_run_logger()
    logger.info(f"[Before]\n{df.info()}")
    df.rename(columns=str.lower, inplace=True)
    logger.info(f"[After]\n{df.info()}")
    return df


@task(description="compress the dataframe and store the file locally", log_prints=True)
def compress_and_store_locally(df: pd.DataFrame, year: int) -> Path:
    logger = get_run_logger()
    os.makedirs(Path('./data'), exist_ok=True)
    path = Path(f"./data/data-{year}.parquet")
    df.to_parquet(path, compression="gzip")
    logger.info(f"Successfully stored the data-{year}.parquet file at {path}")
    return path


@task(description="store the parquet file in the data lake", log_prints=True)
def write_to_gcs(path: Path) -> None:
    gcp_block = GcsBucket.load("data-lake")
    gcp_block.upload_from_path(from_path=path, to_path=path.name)


@task(description="delete the local parquet file of the dataset", log_prints=True)
def delete_local_copy(path: Path) -> None:
    logger = get_run_logger()
    if path.exists():
        logger.info(f"Deleting the file: {path}")
        os.remove(path)
    else:
        logger.info(f"file not found: {path}")


@flow(
    description="child flow for extracting, transforming and loading the dataset from github into the data lake in gcs"
)
def etl_gh_to_gcs(year: int) -> None:
    raw_df = fetch_dataset(year)
    df = transform_headers_to_lowercase(raw_df)
    file_path = compress_and_store_locally(df, year)
    write_to_gcs(file_path)
    delete_local_copy(file_path)


@flow(
    description="parent flow which will spawn child flows based on the number of years provided"
)
def etl_parent_gh_to_gcs(years: List[int]) -> None:
    for year in years:
        etl_gh_to_gcs(year)


if __name__ == "__main__":
    years = [1999]
    etl_parent_gh_to_gcs(years)
