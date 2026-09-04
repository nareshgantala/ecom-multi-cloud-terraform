locals {
  name_prefix = "roboshop-project-demo"

  # Dynamically construct app_services map for the ILB
  app_services = {
    for name, port in var.app_ports : name => {
      port           = port
      instance_group = module.app_vm[name].app_instance_group
    }
  }
}

