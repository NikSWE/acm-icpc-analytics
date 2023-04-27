terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}


provider "tls" {}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "../ssh/id_rsa"
  file_permission = "0600"
}

resource "google_service_account" "service_account" {
  account_id   = var.account_id
  display_name = var.account_id
  description  = "service account created via terraform"
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.name
}

resource "google_project_iam_binding" "service_account_roles" {
  project = var.project_id
  for_each = toset([
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/dataproc.admin"
  ])
  role = each.key
  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "local_file" "service_account_json_key" {
  depends_on = [
    google_service_account.service_account
  ]
  content         = base64decode(google_service_account_key.service_account_key.private_key)
  filename        = "../prefect/service_account_creds.json"
  file_permission = "0644"
}

# Enable required APIs for the project
resource "google_project_service" "cloud_resource_manager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dataproc" {
  service            = "dataproc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}

data "google_client_openid_userinfo" "me" {}

# Provision resources for the project
resource "google_compute_instance" "prefect_vm" {
  name         = "prefect"
  machine_type = "e2-standard-4"
  tags         = ["prefect-vm-rules"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
    }
  }

  depends_on = [
    local_file.service_account_json_key,
    google_project_service.compute,
    google_dataproc_cluster.spark_cluster
  ]
  metadata = {
    ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  connection {
    type        = "ssh"
    user        = split("@", data.google_client_openid_userinfo.me.email)[0]
    host        = self.network_interface[0].access_config[0].nat_ip
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "file" {
    source      = "../prefect/create_blocks.py"
    destination = "create_blocks.py"
  }

  provisioner "file" {
    source      = "../prefect/create_deployments.py"
    destination = "create_deployments.py"
  }

  provisioner "file" {
    source      = "../prefect/etl_gh_to_gcs.py"
    destination = "etl_gh_to_gcs.py"
  }

  provisioner "file" {
    source      = "../prefect/etl_gcs_to_gbq.py"
    destination = "etl_gcs_to_gbq.py"
  }

  provisioner "file" {
    source      = "../prefect/service_account_creds.json"
    destination = "service_account_creds.json"
  }

  provisioner "file" {
    source      = "../prefect/start_pyspark_jobs.py"
    destination = "start_pyspark_jobs.py"
  }

  provisioner "file" {
    source      = "../prefect/requirements.txt"
    destination = "requirements.txt"
  }

  provisioner "file" {
    source      = "../scripts/setup_prefect.sh"
    destination = "setup_prefect.sh"
  }

  provisioner "file" {
    source      = "../pyspark/create_hosts_dimension_table.py"
    destination = "create_hosts_dimension_table.py"
  }

  provisioner "remote-exec" {
    inline = [
      "echo export CLUSTER=${google_dataproc_cluster.spark_cluster.name} >> .bashrc",
      "echo export REGION=${var.region} >> .bashrc",
      "source .bashrc",
      "bash setup_prefect.sh",
      "gcloud auth activate-service-account ${google_service_account.service_account.email} --key-file=service_account_creds.json"
    ]
  }
}

resource "google_compute_firewall" "prefect_vm_rules" {
  name          = "prefect-vm-rules"
  network       = "default"
  target_tags   = ["prefect-vm-rules"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["4200"]
  }
}

resource "google_storage_bucket" "data_lake_bucket" {
  name                        = var.bucket_data_lake
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id                 = "raw_dataset"
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset" "prod_dataset" {
  dataset_id = "prod_dataset"
}

resource "google_bigquery_table" "raw_data" {
  dataset_id          = google_bigquery_dataset.raw_dataset.dataset_id
  table_id            = "raw_data"
  deletion_protection = false
  range_partitioning {
    range {
      start    = 1999
      end      = 2022
      interval = 1
    }
    field = "year"
  }

  schema = file("../bq_schemas/raw_data.json")
}


resource "google_dataproc_cluster" "spark_cluster" {
  name   = "spark-cluster"
  region = var.region

  cluster_config {
    gce_cluster_config {
      zone = var.zone
    }

    master_config {
      num_instances = 1
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_size_gb = 30
      }
    }

    software_config {
      image_version = "2.0-debian10"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
    }
  }
}
