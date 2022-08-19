terraform {
  backend "s3" {
    bucket = # Bucket where you want to store your state remotely 
    region = # Region for the state bucket access
    # Explanation: Change this value when creating a new environment.
    # key    = # The key to avoid state collissions
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = var.assume_role_arn
  }

  default_tags {
    tags = {
      Project     = # Youd defaul tags go here. 
    }
  }
}

module "spot_fleet_request" {
  source             = "./modules/spot_fleet"
  vpc_id             = var.vpc_id
  private_cidr_start = var.private_cidr_start
  transit_gateway_id = var.transit_gateway_id
}
