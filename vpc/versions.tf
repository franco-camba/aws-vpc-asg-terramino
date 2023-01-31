terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
}

provider "tfe" {
  version = "~> 0.41.0"
  ...
}
