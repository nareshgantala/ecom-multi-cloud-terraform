variable "name_prefix" {
  type = string
}

variable "network_id" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "app_services" {
  type = map(object({
    port           = number
    instance_group = string
  }))
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "domain_name" {
  type    = string
  default = "naresh-training.online"
}
