resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
     ansible_group_wp-app = yandex_compute_instance.wp-app[*].labels.ansible-group
     hostaddr_wp-app = yandex_compute_instance.wp-app[*].network_interface[0].nat_ip_address
     hostname_wp-app = yandex_compute_instance.wp-app[*].name
    }
  )
  filename = "../ansible/environments/prod/inventory"
}

resource "local_file" "ansible_groupvars_wp-app" {
  content = templatefile("wp-app.tmpl",
    {
     wordpress_db_name = local.dbname
     wordpress_db_user = local.dbuser
     wordpress_db_password = local.dbpassword
     wordpress_db_host = local.cluster_master_fqdn
    }
  )
  filename = "../ansible/environments/prod/group_vars/wp-app"
}