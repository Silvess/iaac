output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value = tolist(tolist(yandex_lb_network_load_balancer.wp_lb.listener).0.external_address_spec).0.address
}

output "vm_linux_public_ip_address" {
  description = "Virtual machine IP"
  value = yandex_compute_instance.wp-app[0].network_interface[0].nat_ip_address
}

output "vm_linux_2_public_ip_address" {
  description = "Virtual machine IP"
  value = yandex_compute_instance.wp-app[1].network_interface[0].nat_ip_address
}

output "database_host_fqdn" {
  description = "DB hostname"
  value = local.dbhosts
}

output "database_user" {
  description = "User of the created DB"
  value = local.dbuser
}

output "database_name" {
  description = "Name of the created DB"
  value = local.dbname
}

output "database_pass" {
  description = "Password of the created DB"
  sensitive = true
  value = local.dbpassword
}