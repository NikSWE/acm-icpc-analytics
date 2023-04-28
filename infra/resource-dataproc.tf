resource "google_dataproc_cluster" "spark_cluster" {
  name   = "spark-cluster"
  region = var.region

  cluster_config {
    staging_bucket = google_storage_bucket.dataproc_stage_bucket.name
    temp_bucket = google_storage_bucket.dataproc_temp_bucket.name

    gce_cluster_config {
      zone = var.zone
      metadata = {
        "spark-bigquery-connector-url" = "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.30.0.jar"
      }
    }

    master_config {
      num_instances = 1
      machine_type  = "n2-standard-4"
      disk_config {
        boot_disk_size_gb = 30
      }
    }

    software_config {
      image_version = "2.0-debian10"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
      optional_components = [
        "JUPYTER"
      ]
    }

    endpoint_config {
      enable_http_port_access = "true"
    }

    initialization_action {
      script = "gs://goog-dataproc-initialization-actions-${var.region}/connectors/connectors.sh"
    }
  }
}
