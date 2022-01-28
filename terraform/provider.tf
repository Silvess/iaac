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