variable "frontend_component" {
  default = {
    frontend = "e2-small"
  }
}

variable "app_component" {
  default = {
    cart      = "e2-small"
    catalogue = "e2-small"
    shipping  = "e2-small"
    payment   = "e2-small"
    user      = "e2-small"
    ratings   = "e2-small"
    "orders"  = "e2-small"
  }
}

variable "database_component" {
  default = {
    mysql    = "e2-small"
    valky    = "e2-small"
    rabbitmq = "e2-small"
    mongodb  = "e2-small"
  }
}


variable "app_ports" {
  type = map(number)
  default = {
    user      = 8001
    catalogue = 8002
    cart      = 8003
    shipping  = 8004
    payment   = 8005
    ratings   = 8006
    orders    = 8007
  }
}
