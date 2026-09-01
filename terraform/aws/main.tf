module "networking" {
  source      = "../modules/aws/networking"
  vpc_cidr    = var.vpc_cidr
  name_prefix = local.name_prefix

}

module "ec2" {
  for_each          = var.components
  source            = "../modules/aws/ec2"
  ami               = var.ami_id
  instance_type     = each.value
  name_prefix       = local.name_prefix
  component_name    = each.key
  private_subnet_id = module.networking.private_subnet_ids[index(keys(var.components), each.key) % 3]

}
