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
    "roles/bigquery.admin"
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

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
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
    google_project_service.compute
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
    source      = "../prefect/service_account_creds.json"
    destination = "service_account_creds.json"
  }

  provisioner "file" {
    source      = "../prefect/requirements.txt"
    destination = "requirements.txt"
  }

  provisioner "file" {
    source      = "../scripts/setup_prefect.sh"
    destination = "setup_prefect.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash setup_prefect.sh"
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
