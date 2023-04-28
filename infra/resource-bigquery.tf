resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id                 = "raw_dataset"
  delete_contents_on_destroy = true
}

resource "google_bigquery_dataset" "prod_dataset" {
  dataset_id                 = "prod_dataset"
  delete_contents_on_destroy = true
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

  schema = file("${local.schemas_dir}/raw_data.json")
}
