data "terraform_remote_state" "vpc" {
  backend = "local"

  config {
    path = "../deploy-vpc-aws/config/cluster.state.remote"
  }
}

// Pick a random subnet for bastion
# resource "random_shuffle" "bastion_az" {
#   input = ["${join(",", data.terraform_remote_state.vpc.output.vpc_subnets_public)}"] #["us-west-1a", "us-west-1c", "us-west-1d", "us-west-1e"]
#   result_count = 1
# }