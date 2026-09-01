module "networking" {
  source      = "../modules/gcp/networking"
  name_prefix = local.name_prefix
}
