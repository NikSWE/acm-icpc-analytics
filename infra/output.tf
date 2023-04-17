output "prefect_server" {
  description = "the url to access the prefect server"
  value = join("", ["http://", google_compute_instance.prefect_vm.network_interface.0.access_config.0.nat_ip, ":4200"])
}
