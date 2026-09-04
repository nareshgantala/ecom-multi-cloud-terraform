variable "name_prefix" {
  type = string
}

variable "database_subnet_name" {
  type = string
}

variable "app_services" {
  type = map(object({
    port           = number
    instance_group = string
  }))
}


variable "ilb_ip" {
  type = string
}

variable "elb_ip" {
  type = string
}
