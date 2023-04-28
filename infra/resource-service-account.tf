resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${local.ssh_dir}/id_rsa"
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
  filename        = "${local.prefect_dir}/service_account_creds.json"
  file_permission = "0644"
}


data "google_client_openid_userinfo" "me" {}
