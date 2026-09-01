variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}



variable "components" {
  type = map(string)
  default = {
    mongodb  = "t3.micro"
    valkey   = "t3.micro"
    mysql    = "t3.small"
    rabbitmq = "t3.micro"
  }
}


variable "ami_id" {
  default = "ami-00adafae70b8029d8"
}

