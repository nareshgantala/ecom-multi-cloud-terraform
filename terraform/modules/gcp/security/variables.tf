variable "network_id" {
  type = string
}

variable "name_prefix" {
  type = string
}


variable "app_ports" {
  type = map(number)
}
