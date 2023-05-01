# ACM ICPC Analytics


## Technologies

### Project Structure


## Architecture

![pipeline image](./images/pipeline.png)

## Workflow


### Orchestration

![deployments](./images/deployments.png)

| Flows                        | Flow Runs                            |
| ---------------------------- | ------------------------------------ |
| ![flows](./images/flows.png) | ![flow runs](./images/flow_runs.png) |


### Configuration

![blocks](./images/blocks.png)

![agent](./images/agent.png)

### Data Lake

![data lake image](./images/data_lake.png)

### Data Warehouse

| Table Size                               | Table Info                           |
| ---------------------------------------- | ------------------------------------ |
| ![size](./images/raw_data_size.png)      | ![info](./images/raw_data_info.png)  |

<p align="center">
  <img src="./images/dimension_tables.png" />
</p>

### Dashboard

![dashboard image](./images/dashboard.png)

| 1999 - 2011                          | 2012 - 2021                        |
| ------------------------------------ | ---------------------------------- |
| ![1999 - 2011](./images/1999_2011.png) | ![flow runs](./images/2012_2021.png) |


## Deployment

Before you can deploy this project, make sure that you have installed `gcloud` and `terraform` on your machine. The following screenshot shows the versions of these tools during the development of this project:

<p align="center">
  <img src="./images/cli_tools_version.png" />
</p>

To deploy the project, you need to authenticate with `gcloud` first. After that, create a new project either through the CLI or the console UI. Also, make sure to edit the location of the CSV files in the `etl_gh_to_gcs.py` file.

Next, navigate to the `infra` working directory and create a `terraform.tfvars` file. Add values for all the variables mentioned in `variables.tf`. Here is the template you can edit:

```terraform
project_id = ""
region = ""
zone = ""
bucket_data_lake = ""
account_id = ""
```

Finally, run `terraform apply`. Make sure not to delete the state files created by Terraform; otherwise, you won't be able to destroy the resources created in Google Cloud properly.

## Challenges


## Improvements

