// Creake KMS key for EFS encryption
#resource "aws_kms_key" "kube_efs_kms_key" {
#  description             = "KMS key for ${var.cluster_name_short}"
#  deletion_window_in_days = 10
#}

resource "aws_security_group" "efs_sg" {
  name        = "${var.cluster_name_short}-efs"
  // omit `name` as it cannot be changed after it is set initially

  description = "cluster ${var.cluster_name_short} EFS traffic"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
  

  # Allow incoming NFS traffic
  ingress {
    from_port          = "2049"
    to_port            = "2049"
    protocol           = "tcp"
    self               = true
  security_groups = ["${aws_security_group.controller_sg.id}","${aws_security_group.worker_sg.id}"]
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-sg-efs"
    )
  )}"
}

// Create EFS
resource "aws_efs_file_system" "kube_efs" {
  creation_token       = "${var.efs_storage["creation_token"]}"
  performance_mode     = "${var.efs_storage["performance_mode"]}"
  #encrypted            = "${var.efs_storage["encrypted"]}"

  #kms_key_id           = "${aws_kms_key.kube_efs_kms_key.arn}"

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-efs"
    )
  )}"
}

resource "aws_efs_mount_target" "mount_target" {
  file_system_id       = "${aws_efs_file_system.kube_efs.id}"
  subnet_id            = "${element(data.terraform_remote_state.vpc.vpc_subnets_private,count.index)}" # iterate through subnets, use AZ counter
  security_groups      = ["${aws_security_group.efs_sg.id}"]
  count                = "${length(data.terraform_remote_state.vpc.vpc_region_azs)}" # AZ counter, return number of AZs
}

// Outputs
output "kube_efs_id" {
  value = "${aws_efs_file_system.kube_efs.id}"
}

output "kube_efs_dns" {
  value = "${aws_efs_file_system.kube_efs.dns_name}"
}
