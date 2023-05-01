# ACM ICPC Analytics

The ACM ICPC World Finals is often referred to as the Olympics for programmers. Intrigued by this renowned competition, I delved into its history on Wikipedia and discovered that it began in 1970 at Texas A&M University, where participants used Fortran to solve problems. As I continued to explore, I came across the startling fact that since 2000, only teams from Russia, China, and Poland have won the ICPC world finals, with the exception of 2022. This piqued my interest, and I set out to unlock insights about this competition using this [dataset](https://www.kaggle.com/datasets/justinianus/icpc-world-finals-ranking-since-1999?select=icpc-2019.csv) I found on Kaggle. Big thanks to [Hoang Le Ngoc](https://www.kaggle.com/justinianus) for putting together and maintaining this awesome dataset!

Thanks to the knowledge and skills I acquired during the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) hosted by [DataTalks.Club](https://datatalks.club/), I was able to create this project. This course introduced me to numerous open source tools in the data domain, and I was thrilled to put my newfound abilities to the test.

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

The workflow for this project consists of several stages. Initially, the dataset is fetched from the source, after which it is loaded into Google BigQuery. Following this, dimension tables are created by performing various transformations on the raw dataset using PySpark. Finally, an interactive dashboard can be built using the dimension tables, enabling users to analyze and visualize the data in a meaningful way.

### Orchestration

To orchestrate all the tasks in the workflow, I have chosen to use Prefect. Prefect is a modern data workflow management system that allows for the creation, scheduling, and monitoring of complex data pipelines. It offers features such as error handling, task retries, and dynamic dependencies, making it an ideal choice for data engineering projects. Additionally, Prefect integrates seamlessly with various cloud platforms, including Google Cloud, which I used for this project. By using Prefect, I was able to create a reliable and scalable workflow that automates the various tasks involved in processing the dataset and building the dashboard.

![deployments](./images/deployments.png)

| Flows                        | Flow Runs                            |
| ---------------------------- | ------------------------------------ |
| ![flows](./images/flows.png) | ![flow runs](./images/flow_runs.png) |


### Configuration

To simplify the sharing of information among flows, I utilized Prefect blocks to securely and easily manage the configuration related to my project. Prefect blocks are reusable building blocks that allow for the creation of modular, shareable, and easily configurable code. These blocks encapsulate specific functionality and are used to create more complex flows. They can also be parameterized to allow for easy configuration and reuse. In my project, I used Prefect blocks to store the necessary credentials for accessing my Google Cloud services, making it easier to maintain and manage this sensitive information.

![blocks](./images/blocks.png)

To ensure the execution of tasks, Prefect uses agents, which are responsible for running the flows. If an agent is not running, the flows will remain in the scheduled state. To create the default agent, a startup script is executed as part of provisioning the VM for Prefect server. This script contains the necessary configurations and instructions to set up the default agent. By default, Prefect uses the LocalAgent, which runs the tasks locally on the machine where the agent is running. However, it's possible to use other agents like the DaskAgent, which allows distributed computing.

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

Here is the link https://lookerstudio.google.com/s/oWO5PzCrxTU

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

