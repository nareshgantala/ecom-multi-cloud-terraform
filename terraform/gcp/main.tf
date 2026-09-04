module "networking" {
  source      = "../modules/gcp/networking"
  name_prefix = local.name_prefix
}

module "frontend_vm" {
  for_each       = var.frontend_component
  source         = "../modules/gcp/vm"
  machine_type   = each.value
  component      = each.key
  name_prefix    = local.name_prefix
  subnet_name    = module.networking.frontend_subnet_name
  component_type = "frontend"
}

module "app_vm" {
  for_each       = var.app_component
  source         = "../modules/gcp/vm"
  machine_type   = each.value
  component      = each.key
  name_prefix    = local.name_prefix
  subnet_name    = module.networking.app_subnet_name
  component_type = "app"
}

module "database_vm" {
  for_each       = var.database_component
  source         = "../modules/gcp/vm"
  machine_type   = each.value
  component      = each.key
  name_prefix    = local.name_prefix
  subnet_name    = module.networking.database_subnet_name
  component_type = "database"
}

module "frontend_elb" {
  source                  = "../modules/gcp/elb"
  name_prefix             = local.name_prefix
  frontend_instance_group = module.frontend_vm["frontend"].frontend_instance_group
}

module "security" {
  source      = "../modules/gcp/security"
  network_id  = module.networking.vpc_network_id
  name_prefix = local.name_prefix
}



module "dns" {
  source               = "../modules/gcp/dns"
  name_prefix          = local.name_prefix
  database_subnet_name = module.networking.database_subnet_name

}

module "ilb" {
  source      = "../modules/gcp/ilb"
  name_prefix = local.name_prefix
  network_id  = module.networking.vpc_network_id
}
