import pandas as pd
from prefect import flow, task, get_run_logger
from prefect_gcp.cloud_storage import GcsBucket, GcpCredentials
from typing import List
from io import BytesIO


@task(
    description="fetch the parquet for the year provided from the data lake",
    log_prints=True,
    retries=5,
)
def extract_from_gcs(year: int) -> bytes:
    logger = get_run_logger()
    gcs_block = GcsBucket.load("data-lake")
    raw_df = gcs_block.read_path(f"data-{year}.parquet")
    logger.info(f"Successfully downloaded data-{year}.parquet file")
    return raw_df


@task(description="transform date column to month column", log_prints=True)
def transform_date_to_month(df: pd.DataFrame) -> pd.DataFrame:
    logger = get_run_logger()
    df["date"] = pd.to_datetime(df["date"]).dt.month
    df.rename(columns={"date": "month"}, inplace=True)
    logger.info(f"Successfully transformed the date column to month")
    return df


@task(description="drop unused columns from the dataframe", log_prints=True)
def drop_unused_columns(df: pd.DataFrame) -> pd.DataFrame:
    logger = get_run_logger()
    df.drop(
        columns=[
            "rank",
            "team",
            "contestant 1",
            "contestant 2",
            "contestant 3",
            "score percentage",
            "prize",
        ],
        inplace=True,
    )
    logger.info(f"Successfully dropped unused columns from the dataframe")
    return df


@task(description="append the dataframe to the data warehouse", log_prints=True)
def write_to_gbq(df: pd.DataFrame) -> None:
    logger = get_run_logger()
    creds_block = GcpCredentials.load("service-account")
    df.to_gbq(
        destination_table="raw_dataset.raw_data",
        project_id=creds_block.project,
        chunksize=1_000,
        if_exists="append",
        credentials=creds_block.get_credentials_from_service_account(),
        progress_bar=False
    )
    logger.info(f"Successfully added the dataframe to gbq")
    return df


@flow(
    description="child flow for extracting, transforming and loading the dataset from gcs into the data warehouse in gbq"
)
def etl_gcs_to_gbq(year: int) -> None:
    raw_df = extract_from_gcs(year)
    df = pd.read_parquet(BytesIO(raw_df))
    df = transform_date_to_month(df)
    df = drop_unused_columns(df)
    write_to_gbq(df)


@flow(
    description="parent flow which will spawn child flows based on the number of years provided"
)
def etl_parent_gcs_to_gbq(years: List[int]) -> None:
    for year in years:
        etl_gcs_to_gbq(year)


if __name__ == "__main__":
    years = [1999]
    etl_parent_gcs_to_gbq(years)
