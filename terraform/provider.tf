provider "yandex" {
  service_account_key_file = var.yc_service_account_key_file
  cloud_id  = var.yc_cloud
  folder_id = var.yc_folder
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}
