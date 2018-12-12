// Define backend state location of this template (Used for remote state elsewhere)
# terraform {
#   backend "local" {
#     path = "config/terraform.tfstate"
#   }
# }

// An example of using an S3 backend
# terraform {
#   backend "s3" {
#     bucket  = "BUCKETNAME"
#     key     = "prod/terraform.tfstate"
#     region  = "eu-west-1"
#     encrypt = true
#   }
# }

// Pull in remote state of base VPC
data "terraform_remote_state" "vpc" {
  backend = "local"

  config {
    // This is required to read the state of the deployed VPC used in other repo:
    // https://github.com/KptnKMan/deploy-vpc-aws
    path = "../deploy-vpc-aws/terraform.tfstate"
  }
}

// Pick a random PUBLIC subnet from AZ list (Eg: for bastion in random AZ)
resource "random_shuffle" "random_az" {
  input = ["${data.terraform_remote_state.vpc.vpc_subnets_public}"]
  result_count = 1
}

//Outputs
output "path_module" {
  value = "${path.module}"
}

// Outputs from remote state file
output "_connect_bastion_ip" {
  value = "${data.terraform_remote_state.vpc._connect_bastion_ip}"
}

output "_connect_bastion_dns" {
  value = "${data.terraform_remote_state.vpc._connect_bastion_dns}"
}