# Домашнее задание к занятию “Terraform как инструмент для декларативного описания инфраструктуры”

## Цель работы
Подготовить отказоустойчивую облачную инфраструктуру для последующей установки Wordpress.

## Создание манифестов Terraform

### provider.tf
Здесь описываются параметры подключения к Yandex.Cloud.
Использование токена для подключения небезопасно, поэтому было выполнено задание (*) по подключению с использованием сервисного аккаунта (`service_account_key_file = ...`).
```hcl
provider "yandex" {
  cloud_id  = var.yc_cloud
  folder_id = var.yc_folder
  service_account_key_file = var.yc_service_account_key_file
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

```

### variables.tf
Здесь описываются параметры, используемые в манифестах. Значения (кроме значений по умолчанию) указываются в неотслеживаемом файле *wp.auto.tfvars*.
Добавлены переменные: 
`yc_service_account_key_file` - путь к ключу сервисного аккаунта Yandex.Cloud; 
`zones` - список используемых зон доступности облака, с указанием параметров по умолчанию в виде трех зон
`instance_count` - количество создаваемых инстансов вм приложений.

```hcl
variable "yc_cloud" {
  type = string
  description = "Yandex Cloud ID"
}

variable "yc_folder" {
  type = string
  description = "Yandex Cloud folder"
}

variable "yc_service_account_key_file" {
  type = string
  description = "Path to Service account key file"
}

variable "db_password" {
  description = "MySQL user pasword"
}

variable "zones" {
  description = "availability zone of yandex cloud"
  default = ["ru-central1-a","ru-central1-b","ru-central1-c"]
}

variable "instance_count" {
  description = "number of instances created"
  default = "2"
}
```

### network.tf
Здесь описано создание сети и подсетей. В каждой из указанной в переменной `zones` зон создается по одной подсети с автоматическим назначением блока адресов.

```hcl
resource "yandex_vpc_network" "wp-network" {
  name = "wp-network"
}

resource "yandex_vpc_subnet" "wp-subnet" {
  count = length(var.zones)
  v4_cidr_blocks = [cidrsubnet("10.0.0.0/8",8,count.index + 1)]
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.wp-network.id
}
```

### wp-app.tf
В этом манифесте описано создание виртуальных машин под развертывание Wordpress. 
Для выполнения задания (**) добавлена возможность управлять количеством создаваемых инстансов с помощью переменной. Для управления количеством инстансов используется мета-аргумент `count` и переменная `instance_count` (`count = var.instance_count`).
Имена машин формируются автоматически путем добавления значения индекса `count`, увеличенного на единицу для удобства восприятия (`name = "wp-app-${count.index + 1}"`). 
Зона доступности выбирается циклически путем сопоставления значения переменной `zones` текущему индексу `count` (`zone = element(var.zones,count.index`).
ID подсети в блоке *network_interface* также, назначается по такому же принципу, только вместо переменной используется массив значений созданных ранее подсетей (`subnet_id = element(yandex_vpc_subnet.wp-subnet[*].id,count.index)`).


```hcl
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
    subnet_id = element(yandex_vpc_subnet.wp-subnet[*].id,count.index)
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/yc.pub")}"
  }
}
```

### lb.tf
Здесь описано создание балансировщика.
Для выполнения задания (**) в блоке *yandex_lb_target_group* использован динамический блок для создания нескольких блоков *target*. Итерация происходит по массиву сетевых интерфейсов виртуальных машин, созданных ранее (*wp-app*) (`dynamic "target" { ... }`). Таким образом, в target_group балансировщика попадают адреса всех виртуальных машин, созданных ранее.

```hcl
resource "yandex_lb_target_group" "wp_tg" {
  name      = "wp-target-group"

   dynamic "target" {
    for_each = yandex_compute_instance.wp-app[*].network_interface.0
    content {
      subnet_id = target.value["subnet_id"]
      address   = target.value["ip_address"]
    }
}
}

resource "yandex_lb_network_load_balancer" "wp_lb" {
  name = "wp-network-load-balancer"

  listener {
    name = "wp-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.wp_tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/health"
      }
    }
  }
}
```

### db.tf
Здесь описано создание кластера СУБД MySQL.

```hcl
locals {
  dbuser = tolist(yandex_mdb_mysql_cluster.wp_mysql.user.*.name)[0]
  dbpassword = tolist(yandex_mdb_mysql_cluster.wp_mysql.user.*.password)[0]
  dbhosts = yandex_mdb_mysql_cluster.wp_mysql.host.*.fqdn
  dbname = tolist(yandex_mdb_mysql_cluster.wp_mysql.database.*.name)[0]
}

resource "yandex_mdb_mysql_cluster" "wp_mysql" {
  name        = "wp-mysql"
  folder_id   = var.yc_folder
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.wp-network.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 16
  }

  database {
    name  = "db"
  }

  user {
    name     = "user"
    password = var.db_password
    authentication_plugin = "MYSQL_NATIVE_PASSWORD"
    permission {
      database_name = "db"
      roles         = ["ALL"]
    }
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.wp-subnet[1].id
    assign_public_ip = true
  }
  host {
    zone      = "ru-central1-c"
    subnet_id = yandex_vpc_subnet.wp-subnet[2].id
    assign_public_ip = true
  }
}
```

### output.tf
Описан вывод IP-адреса балансировщика и DNS-имен хостов СУБД.

```hcl
output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value = yandex_lb_network_load_balancer.wp_lb.listener.*.external_address_spec[0].*.address
}

output "database_host_fqdn" {
  description = "DB hostname"
  value = local.dbhosts
}
```
