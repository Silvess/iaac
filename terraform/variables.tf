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
