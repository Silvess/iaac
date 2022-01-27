resource "yandex_compute_instance" "wp-app" {
  count = var.instance_count
  name = "wp-app-${count.index + 1}"
  zone = element(var.zones,count.index)

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80viupr3qjr5g6g9du"
    }
  }

  network_interface {
    #subnet_id = yandex_vpc_subnet.wp-subnet[0].id
    subnet_id = element(yandex_vpc_subnet.wp-subnet[*].id,count.index)
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yc.pub")}"
  }
}