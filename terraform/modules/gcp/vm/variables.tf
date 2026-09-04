variable "name_prefix" {
  type = string
}


variable "machine_type" {
  type = string
}

variable "component" {
  type = string
}

variable "subnet_name" {

}

variable "component_type" {
  type = string
}


variable "port" {
  type    = number
  default = 80
}

variable "static_ip" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = "us-west1"
}
