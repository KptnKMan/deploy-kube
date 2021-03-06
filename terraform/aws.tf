// Declare AWS provider for basically everything to follow
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  # profile    = "customprofile"
  region = "${var.aws_region}"
}

// Define the common tags for all resources
// https://github.com/hashicorp/terraform/blob/master/website/docs/configuration/locals.html.md
locals {
  aws_tags = {
    Role           = "${var.cluster_tags["Role"]}"
    Service        = "${var.cluster_tags["Service"]}"
    Business-Unit  = "${var.cluster_tags["Business-Unit"]}"
    Owner          = "${var.cluster_tags["Owner"]}"
    Purpose        = "${var.cluster_tags["Purpose"]}"
    Terraform      = "True"
  }
}
# Extra Tags:
# Name: "Some Resource" <-- required
# RetentionPriority: "1-5" <-- optional
#
# Use common tags in resources with below example:
#
#  tags = "${merge(
#    local.aws_tags,
#    map(
#      "Name", "awesome-app-server"
#    )
#  )}"

// Backup bucket, used by etcd
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "${var.s3_backup_bucket}"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-s3-backup"
    )
  )}"
}

// State bucket, available for storing data
resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.s3_state_bucket}"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-s3-state"
    )
  )}"
}
