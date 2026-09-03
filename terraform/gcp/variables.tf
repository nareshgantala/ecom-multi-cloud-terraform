variable "frontend_component" {
  default = {
    frontend = "n4-standard-2"
  }
}

variable "app_component" {
  default = {
    cart      = "n4-standard-2"
    catalogue = "n4-standard-2"
    shipping  = "n4-standard-2"
    payment   = "n4-standard-2"
    user      = "n4-standard-2"
    ratings   = "n4-standard-2"
    "orders"  = "n4-standard-2"
  }
}

variable "database_component" {
  default = {
    mysql    = "n4-standard-2"
    valky    = "n4-standard-2"
    rabbitmq = "n4-standard-2"
    mongo    = "n4-standard-2"
  }
}
