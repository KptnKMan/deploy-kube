// Creake KMS key for EFS encryption
#resource "aws_kms_key" "kube_efs_kms_key" {
#  description             = "KMS key for ${var.cluster_name_short}"
#  deletion_window_in_days = 10
#}

resource "aws_security_group" "efs_sg" {
  name        = "${var.cluster_name_short}-efs"
  // omit `name` as it cannot be changed after it is set initially

  description = "Rules for ${var.cluster_name_short} EFS"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
  

  # Allow incoming NFS traffic
  ingress {
    from_port          = "2049"
    to_port            = "2049"
    protocol           = "tcp"
    self               = true
  security_groups = ["${aws_security_group.controller_sg.id}","${aws_security_group.worker_sg.id}"]
  }

  tags {
    Name               = "${var.cluster_name_short}-sg-efs"
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

// Create EFS
resource "aws_efs_file_system" "kube_efs" {
  creation_token       = "${var.efs_storage["creation_token"]}"
  performance_mode     = "${var.efs_storage["performance_mode"]}"
  #encrypted            = "${var.efs_storage["encrypted"]}"

  #kms_key_id           = "${aws_kms_key.kube_efs_kms_key.arn}"

  tags {
    Name               = "${var.cluster_name_short}-efs"
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

resource "aws_efs_mount_target" "mount_target" {
  file_system_id       = "${aws_efs_file_system.kube_efs.id}"
  subnet_id            = "${element(data.terraform_remote_state.vpc.vpc_subnets_private,count.index)}" # iterate through subnets, use AZ counter
  security_groups      = ["${aws_security_group.efs_sg.id}"]
  count                = "${length(var.aws_availability_zones)}" # AZ counter, return number of AZs
}

// Outputs
output "kube_efs_id" {
  value = "${aws_efs_file_system.kube_efs.id}"
}

output "kube_efs_dns" {
  value = "${aws_efs_file_system.kube_efs.dns_name}"
}
