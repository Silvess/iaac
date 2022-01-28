# Домашнее задание к занятию “Terraform как инструмент для декларативного описания инфраструктуры”
____
## Цель работы
Подготовить отказоустойчивую облачную инфраструктуру для последующей установки Wordpress.

## Создание манифестов терраформа

### provider.tf
Здесь описываются параметры подключения к Yandex.Cloud.
Использование для подключения токена небезопасно, поэтому было выполнено задание (*) по подключению с использованием сервисного аккаунта.
```hcl
provider "yandex" {
  cloud_id  = var.yc_cloud
  folder_id = var.yc_folder
  service_account_key_file = var.yc_service_account_key_file
  #token = var.yc_token
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

```