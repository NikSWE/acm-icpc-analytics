import pandas as pd
from prefect import flow, task, get_run_logger
from prefect_gcp.cloud_storage import GcsBucket, DataFrameSerializationFormat
from typing import List
import numpy as np


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


# Since the dataset doen not contain this detail
@task(
    description="add a column indicating the programming language used during the world finals",
    log_prints=True,
)
def add_language_column(df: pd.DataFrame) -> pd.DataFrame:
    logger = get_run_logger()
    languages = ["java", "cpp", "c", "kotlin", "python"]
    df["language"] = np.random.choice(languages, size=len(df))
    logger.info(f"Successfully added the language column")
    return df


@task(description="transform the column headers to lowercase", log_prints=True)
def transform_headers_to_lowercase(df: pd.DataFrame) -> pd.DataFrame:
    logger = get_run_logger()
    logger.info(f"[Before]\n{df.info()}")
    df.rename(columns=str.lower, inplace=True)
    logger.info(f"[After]\n{df.info()}")
    return df


@task(description="store the dataframe in the data lake", log_prints=True)
def write_to_gcs(df: pd.DataFrame, year: int) -> None:
    gcp_block = GcsBucket.load("data-lake")
    gcp_block.upload_from_dataframe(
        df,
        to_path=f"data-{year}.parquet",
        serialization_format=DataFrameSerializationFormat.PARQUET,
    )


@flow(
    description="child flow for extracting, transforming and loading the dataset from github into the data lake in gcs"
)
def etl_gh_to_gcs(year: int) -> None:
    raw_df = fetch_dataset(year)
    df = transform_headers_to_lowercase(raw_df)
    df = add_language_column(df)
    write_to_gcs(df, year)


@flow(
    description="parent flow which will spawn child flows based on the number of years provided"
)
def etl_parent_gh_to_gcs(years: List[int]) -> None:
    for year in years:
        etl_gh_to_gcs(year)


if __name__ == "__main__":
    years = [1999]
    etl_parent_gh_to_gcs(years)
