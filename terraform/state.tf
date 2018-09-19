// Pull in remote state of base VPC
data "terraform_remote_state" "vpc" {
  backend = "local"

  config {
    path = "../deploy-vpc-aws/config/cluster.state"
  }
}

// Pick a random PUBLIC subnet from AZ list (Eg: for bastion in random AZ)
resource "random_shuffle" "random_az" {
  input = ["${data.terraform_remote_state.vpc.vpc_subnets_public}"]
  result_count = 1
}

// Define state location of this template (Used for remote state elsewhere)
terraform {
  backend "local" {
    path = "config/cluster.state"
  }
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