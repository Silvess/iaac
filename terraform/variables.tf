variable "yc_cloud" {
  type = string
  description = "Yandex Cloud ID"
}

variable "yc_folder" {
  type = string
  description = "Yandex Cloud folder"
}

variable "yc_token" {
  type = string
  description = "Yandex Cloud folder"
}

#variable "yc_service_account_key_file" {
#  type = string
#  description = "Path to Service account key file"
#}

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
