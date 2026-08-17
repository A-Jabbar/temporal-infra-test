module "network" {
  source = "./modules/network"

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
  project_name         = var.project_name
  tags                 = var.default_tags
  bastion_allowed_cidr = var.bastion_allowed_cidr
  app_ports            = var.app_ports
  db_port              = var.db_port
}
