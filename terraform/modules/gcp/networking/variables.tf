variable "name_prefix" {
  type = string
}

variable "frontend_cidr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "app_cidr" {
  type    = string
  default = "10.2.0.0/24"
}

variable "database_cidr" {
  type    = string
  default = "10.3.0.0/24"
}
