resource "aws_instance" "main" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id
  tags = {
    Name = "${var.name_prefix}-${var.component_name}"
  }
}
