from prefect_gcp import GcpCredentials
from prefect_gcp.cloud_storage import GcsBucket
import json

with open("service_account_creds.json") as f:
    contents = f.read()

service_account_info = json.loads(contents)

GcpCredentials(service_account_info=service_account_info).save(
    "service-account", overwrite=True
)

GcsBucket(
    gcp_credentials=GcpCredentials.load("service-account"),
    bucket="acm-icpc-world-finals-data",
).save("data-lake", overwrite=True)
