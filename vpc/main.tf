provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      workspace = "terramino-vpc"
    }
  }
}

variable "cidr" {
  type = string
}

variable "subnets" {
  type = set(string)
}

variable "retired_subnets" {
  type    = set(string)
  default = []
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main-vpc"
  cidr = var.cidr

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = var.subnets
  enable_dns_hostnames = true
  enable_dns_support   = true
}

locals {
  subnet_cidr = {
    for i, subnet in module.vpc.public_subnets :
    subnet => module.vpc.public_subnets_cidr_blocks[i]
  }
  public_subnets = [
    for subnet in module.vpc.public_subnets :
    subnet if !contains(var.retired_subnets, local.subnet_cidr[subnet])
  ]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = local.public_subnets
}
