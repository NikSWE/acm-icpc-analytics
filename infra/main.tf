terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.61.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
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

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

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

  metadata_startup_script = file("../scripts/setup_prefect.sh")

  network_interface {
    network = "default"
    access_config {}
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
