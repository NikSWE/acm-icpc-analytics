from dotenv import load_dotenv

# Load in all the environment variables
load_dotenv()

from kaggle.api.kaggle_api_extended import KaggleApi
import os
import pandas as pd
from prefect import flow, task, get_run_logger
from pathlib import Path
from prefect_gcp.cloud_storage import GcsBucket


@task(name="extract dataset from kaggle", log_prints=True, retries=5)
def fetch(year: int) -> pd.DataFrame:
    logger = get_run_logger()

    api = KaggleApi()
    api.authenticate()

    DATA_DIR = Path("./data")
    os.makedirs(name=DATA_DIR, exist_ok=True)

    api.dataset_download_file(
        "justinianus/icpc-world-finals-ranking-since-1999",
        file_name=f"icpc-{year}.csv",
        path=DATA_DIR,
        force=True,
    )

    logger.info(f"Successfully downloaded icpc-{year}.csv dataset")
    return pd.read_csv(f"{DATA_DIR}/icpc-{year}.csv")


@task(name="compress dataset and store locally", log_prints=True, retries=5)
def compress_and_store(df: pd.DataFrame, year: int) -> Path:
    logger = get_run_logger()

    path = Path(f"./data/data-{year}.parquet")
    df.to_parquet(path, compression="gzip")

    logger.info(f"Successfully compressed dataset data-{year}.parquet")
    return path


@task(name="write to the data lake", log_prints=True)
def write_to_gcs(path: Path) -> None:
    gcp_block = GcsBucket.load("data-lake")
    gcp_block.upload_from_path(from_path=path, to_path=path.name)


@flow(name="main etl function", log_prints=True)
def etl_kaggle_to_gcs() -> None:
    df = fetch(1999)
    local = compress_and_store(df, 1999)
    write_to_gcs(local)


if __name__ == "__main__":
    etl_kaggle_to_gcs()
