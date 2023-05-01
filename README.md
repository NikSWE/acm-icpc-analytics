# ACM ICPC Analytics

The ACM ICPC World Finals is often referred to as the Olympics for programmers. Intrigued by this renowned competition, I delved into its history on Wikipedia and discovered that it began in 1970 at Texas A&M University, where participants used Fortran to solve problems. As I continued to explore, I came across the startling fact that since 2000, only teams from Russia, China, and Poland have won the ICPC world finals, with the exception of 2022. This piqued my interest, and I set out to unlock insights about this competition using a [dataset](https://www.kaggle.com/datasets/justinianus/icpc-world-finals-ranking-since-1999?select=icpc-2019.csv) I found on Kaggle. Big thanks to [Hoang Le Ngoc](https://www.kaggle.com/justinianus) for putting together and maintaining this awesome dataset!

Thanks to the knowledge and skills I acquired during the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) hosted by [DataTalks.Club](https://datatalks.club/), I was able to create this project. This course introduced me to numerous open-source tools in the data domain, and I was thrilled to put my newfound abilities to the test.

## Technologies

During the development of this project, I utilized various technologies that were covered in the Data Engineering Zoomcamp.

1. Google Cloud Storage: was used as the data lake
2. Google BigQuery: was used as the data warehouse
3. Google Dataproc: for executing spark jobs
4. Google Looker Studio: for building an interactive dashboard
5. Google Cloud Compute: for hosting a private instance of Prefect 

### Project Structure

This project contains the following directories:

- `images`: contains all the screenshots captured for writing this readme
- `infra`: contains all the Terraform scripts needed to provision resources on Google Cloud
- `prefect`: contains all the Prefect jobs and configurations
- `pyspark`: contains all the Spark jobs used for building dimension tables
- `schemas`: contains the JSON representation of the tables created in Google BigQuery
- `scripts`: contains some handy scripts to make setting up the Prefect server a breeze.

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

