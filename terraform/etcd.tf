// Security Group for the etcd servers
resource "aws_security_group" "etcd_sg" {
  name        = "${var.cluster_name_short}-sg-etcd"
  description = "ETCD traffic"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  // Allow ETCD traffic from kubernetes and bastion groups
  ingress {
    from_port       = "2379"
    to_port         = "2379"
    protocol        = "tcp"
    self            = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow ETCD traffic from kubernetes and bastion groups
  ingress {
    from_port       = "2380"
    to_port         = "2380"
    protocol        = "tcp"
    self            = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow ETCD traffic from kubernetes and bastion groups
  ingress {
    from_port       = "4001"
    to_port         = "4001"
    protocol        = "tcp"
    self            = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow ETCD traffic from kubernetes and bastion groups
  ingress {
    from_port       = "7001"
    to_port         = "7001"
    protocol        = "tcp"
    self            = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  tags {
    Name               = "${var.cluster_name_short}-sg-etcd"
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

// Cloud config file template for etcd
data "template_file" "etcd_ubuntu_cloud_config" {
  template = "${file("terraform/templates/etcd_ubuntu_cloud_config.yml")}"

  vars {
    etcd_backup_bucket = "${aws_s3_bucket.backup_bucket.id}"
    docker_version     = "${var.kubernetes["docker_version"]}"
    etcd_version       = "${var.kubernetes["etcd_version"]}"
    cluster_name_short = "${var.cluster_name_short}"
  }
}

// Launch configuration for ETCD cluster servers
resource "aws_launch_configuration" "etcd_configuration" {
  name_prefix = "${var.cluster_name_short}-etcd-"

  image_id             = "${data.terraform_remote_state.vpc.ami_id_ubuntu}" #"${lookup(var.ubuntu_amis, var.aws_region)}"
  instance_type        = "${var.instance_types["etcd"]}"
  iam_instance_profile = "${data.terraform_remote_state.vpc.iam_instance_profile}"

  spot_price           = "${var.instance_types["spot_max_bid"]}"

  key_name             = "${data.terraform_remote_state.vpc.key_pair_name}"

  user_data            = "${data.template_file.etcd_ubuntu_cloud_config.rendered}"
  security_groups      = ["${data.terraform_remote_state.vpc.common_sg_id}", "${aws_security_group.etcd_sg.id}"]

  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "200"
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = ["user_data"]
    create_before_destroy = true
  }

  #ebs_optimized = true # not supported on spot
}

// AutoScaling group using CloudFormation
resource "aws_cloudformation_stack" "etcd_group" {
  depends_on = [
    "null_resource.render_certs","null_resource.kubeconfig_admin",
    "aws_s3_bucket_object.ca_key","aws_s3_bucket_object.ca_cert",
    "aws_s3_bucket_object.apiserver_key","aws_s3_bucket_object.apiserver_cert",
    "aws_s3_bucket_object.admin_key","aws_s3_bucket_object.admin_cert",
    "aws_s3_bucket_object.worker_key","aws_s3_bucket_object.worker_cert",
    "aws_s3_bucket_object.dashboard_key","aws_s3_bucket_object.dashboard_cert"
  ]
  name = "${var.cluster_name_short}-etcd"

  template_body = <<EOF
{
  "Resources": {
    "Etcd${var.cluster_name_short}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "VPCZoneIdentifier": ["${join(",", data.terraform_remote_state.vpc.vpc_subnets_private)}"],
        "LaunchConfigurationName": "${aws_launch_configuration.etcd_configuration.name}",
        "LoadBalancerNames": ["${aws_elb.etcd_elb.name}"],
        "MinSize": "${var.instances["etcd_min"]}",
        "MaxSize": "${var.instances["etcd_max"]}",
        "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"],
        "Tags": [{
          "Key": "Name",
          "Value": "${var.cluster_name_short}-etcd",
          "PropagateAtLaunch": "true"
        },{
          "Key": "kubernetes.io/cluster/${var.cluster_name_short}",
          "Value": "owned",
          "PropagateAtLaunch": "true"
        },{
          "Key": "KubernetesCluster",
          "Value": "${var.cluster_name_short}",
          "PropagateAtLaunch": "true"
        }]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MaxBatchSize": "1",
          "PauseTime": "${var.instance_types["etcd_wait"]}"
        }
      }
    },
    "Etcd${var.cluster_name_short}LifecycleHookQueue": {
        "Type": "AWS::SQS::Queue"
    },
    "Etcd${var.cluster_name_short}LifecycleHookTerminating": {
      "Type": "AWS::AutoScaling::LifecycleHook",
      "Properties": {
        "AutoScalingGroupName": { "Ref": "Etcd${var.cluster_name_short}" },
        "NotificationTargetARN": { "Fn::GetAtt": ["Etcd${var.cluster_name_short}LifecycleHookQueue", "Arn"] },
        "RoleARN": "${data.terraform_remote_state.vpc.iam_role_lifecycle}",
        "LifecycleTransition": "autoscaling:EC2_INSTANCE_TERMINATING",
        "HeartbeatTimeout": "30"
      }
    }
  }
}
EOF
}

// Internal loadbalancer used for initial ETCD cluster lookup
resource "aws_elb" "etcd_elb" {
  name     = "${var.cluster_name_short}-elb-etcd"

  subnets  = ["${data.terraform_remote_state.vpc.vpc_subnets_private}"]
  
  internal = true

  idle_timeout = 100

  listener {
    instance_port     = 2379
    instance_protocol = "tcp"
    lb_port           = 2379
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 2380
    instance_protocol = "tcp"
    lb_port           = 2380
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 4001
    instance_protocol = "tcp"
    lb_port           = 4001
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 7001
    instance_protocol = "tcp"
    lb_port           = 7001
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    target              = "TCP:2379"
    interval            = 10
  }

  cross_zone_load_balancing = true
  security_groups           = ["${data.terraform_remote_state.vpc.common_sg_id}","${aws_security_group.etcd_sg.id}"]

  tags {
    Name               = "${var.cluster_name_short}-elb-etcd-public"
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

// Outputs
output "aws_elb_dns_etcd" {
  value = "${aws_elb.etcd_elb.dns_name}"
}