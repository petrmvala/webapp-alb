provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = "~> 0.12.30"
}

module "webapp-alb" {
  source      = "../../modules/webapp-alb"
  target_port = 8080
  ssh_key     = "pokus"
  tags        = local.tags
}

locals {
  tags = {
    Application = "webapp-alb"
    DeployedBy  = "Terraform"
    Environment = "Development"
  }
}

output "app_endpoint" {
  value = module.webapp-alb.app_endpoint
}

output "bastion" {
  value = module.webapp-alb.bastion
}
