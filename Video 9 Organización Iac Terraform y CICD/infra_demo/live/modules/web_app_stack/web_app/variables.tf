variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_service_plan_id" {
  type    = string
  default = null
}

variable "service_plan_sku" {
  type    = string
  default = "F1"
}
