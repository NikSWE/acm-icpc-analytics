resource "google_project_service" "api" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "dataproc.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}
