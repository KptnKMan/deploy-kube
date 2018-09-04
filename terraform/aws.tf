// Declare AWS provider for basically everything to follow
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

// Backup bucket, used by etcd
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "${var.s3_backup_bucket}"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    Terraform          = "${var.cluster_tags["Terraform"]}"
    Env                = "${var.cluster_tags["Env"]}"
    Role               = "${var.cluster_tags["Role"]}"
    Owner              = "${var.cluster_tags["Owner"]}"
    Team               = "${var.cluster_tags["Team"]}"
    Project-Budget     = "${var.cluster_tags["Project-Budget"]}"
    ScheduleInfo       = "${var.cluster_tags["ScheduleInfo"]}"
    MonitoringInfo     = "${var.cluster_tags["MonitoringInfo"]}"
  }
}

// State bucket, available for storing data
resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.s3_state_bucket}"
  acl    = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    Terraform          = "${var.cluster_tags["Terraform"]}"
    Env                = "${var.cluster_tags["Env"]}"
    Role               = "${var.cluster_tags["Role"]}"
    Owner              = "${var.cluster_tags["Owner"]}"
    Team               = "${var.cluster_tags["Team"]}"
    Project-Budget     = "${var.cluster_tags["Project-Budget"]}"
    ScheduleInfo       = "${var.cluster_tags["ScheduleInfo"]}"
    MonitoringInfo     = "${var.cluster_tags["MonitoringInfo"]}"
  }
}
