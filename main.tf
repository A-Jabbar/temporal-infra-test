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

module "web" {
  source = "./modules/web"

  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  environment        = var.environment
  project_name       = var.project_name
  tags               = var.default_tags

  certificate_arn   = var.certificate_arn
  instance_type     = var.web_instance_type
  desired_capacity  = var.web_desired_capacity
  min_size          = var.web_min_size
  max_size          = var.web_max_size
  cpu_target_value  = var.web_cpu_target_value
  alb_ingress_cidrs = var.web_alb_ingress_cidrs
}

module "security_logging" {
  source = "./modules/security_logging"

  environment  = var.environment
  project_name = var.project_name
  tags         = var.default_tags
  vpc_ids      = [module.network.vpc_id]
}
