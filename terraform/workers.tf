// Security Group for Worker Nodes
resource "aws_security_group" "worker_sg" {
  name        = "${var.cluster_name_short}-sg-worker"
  description = "Worker traffic"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  // Allow external application access (This is default port range)
  // This should also be opened to VPC for ELBs etc
  ingress {
    from_port = "30000"
    to_port   = "32767"
    protocol  = "tcp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow external application access to all management IPs (This is default port range)
  ingress {
    from_port = "30000"
    to_port   = "32767"
    protocol  = "tcp"
    cidr_blocks = [
      "${split(",", data.terraform_remote_state.vpc.management_ips)}",
      "${split(",", data.terraform_remote_state.vpc.management_ips_personal)}"
    ]
  }

  // Allow Kubelet API access for exec and logs
  ingress {
    from_port = "10250"
    to_port   = "10250"
    protocol  = "tcp"
    self      = true
    security_groups = ["${aws_security_group.controller_sg.id}"]
  }

  // Allow Kubelet API access for heapster
  ingress {
    from_port = "10255"
    to_port   = "10255"
    protocol  = "tcp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow all systems for flannel overlay networking
  ingress {
    from_port = "8285"
    to_port   = "8285"
    protocol  = "udp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  // Allow all systems for flannel overlay networking
  ingress {
    from_port = "8472"
    to_port   = "8472"
    protocol  = "udp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.common_sg_id}"]
  }

  tags {
    Name               = "${var.cluster_name_short}-sg-worker"
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

// THIS IS USED FOR PUBLIC ACCESS TO HTTPS PORTS FOR ALL WORKERS
#resource "aws_security_group_rule" "allow_all_https_public" {
#  type              = "ingress"
#  from_port         = 443
#  to_port           = 443
#  protocol          = "tcp"
#  cidr_blocks       = "0.0.0.0/0"
#  source_security_group_id = "${aws_security_group.worker_sg.id}"
#}

// Cloud Config file for worker nodes
data "template_file" "cloud_config_ubuntu_worker" {
  template = "${file("terraform/templates/cloud_config_ubuntu_worker.yaml")}"

  vars {
    docker_version     = "${var.kubernetes["docker_version"]}"
    kubernetes_version = "${var.kubernetes["kube_version"]}"
    flannel_version    = "${var.kubernetes["flannel_version"]}"
    instance_group     = "on-demand"

    service_ip         = "${var.kubernetes["service_ip"]}"
    service_ip_range   = "${var.kubernetes["service_ip_range"]}"
    cluster_cidr       = "${var.kubernetes["service_ip_range"]}"
    flannel_network    = "${var.kubernetes["flannel_network"]}"
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    api_server_secure_port    = "${var.kubernetes["api_server_secure_port"]}"
    api_server_insecure_port = "${var.kubernetes["api_server_insecure_port"]}"
    etcd_endpoints     = "http://${aws_elb.etcd_elb.dns_name}:2379"
    kubernetes_api_elb = "${aws_elb.kubernetes_api_elb.dns_name}"
    kubernetes_api_elb_internal = "${aws_elb.kubernetes_api_elb_internal.dns_name}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"

    aws_region         = "${var.aws_region}"
    url_admiral        = "${var.dns_urls["url_admiral"]}"
    dns_domain_public  = "${var.dns_domain_public}"
  }
}

// Launch configuration for Kubernetes worker nodes
resource "aws_launch_configuration" "worker_configuration" {
  name_prefix = "${var.cluster_name_short}-worker"

  image_id             = "${data.terraform_remote_state.vpc.ami_id_ubuntu}" #"${lookup(var.ubuntu_amis, var.aws_region)}"
  instance_type        = "${var.instance_types["worker"]}"
  iam_instance_profile = "${data.terraform_remote_state.vpc.iam_instance_profile}"

  spot_price           = "${var.instance_types["spot_max_bid"]}"

  key_name             = "${data.terraform_remote_state.vpc.key_pair_name}"

  user_data            = "${data.template_file.cloud_config_ubuntu_worker.rendered}"
  security_groups      = ["${data.terraform_remote_state.vpc.common_sg_id}", "${aws_security_group.worker_sg.id}"]

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

// Define our AutoScaling group using CloudFormation
resource "aws_cloudformation_stack" "worker_group" {
  depends_on = ["aws_cloudformation_stack.controller_group"]
  name = "${var.cluster_name_short}-workers"

  template_body = <<EOF
{
  "Resources": {
    "Workers${var.cluster_name_short}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "VPCZoneIdentifier": ["${join(",", data.terraform_remote_state.vpc.vpc_subnets_public)}"],
        "LaunchConfigurationName": "${aws_launch_configuration.worker_configuration.name}",
        "LoadBalancerNames": ["${aws_elb.kubernetes_public_elb.name}"],
        "MinSize": "${var.instances["worker_min"]}",
        "MaxSize": "${var.instances["worker_max"]}",
        "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"],
        "Tags": [{
          "Key": "Name",
          "Value": "${var.cluster_name_short}-worker",
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
          "PauseTime": "${var.instance_types["worker_wait"]}"
        }
      }
    }
  }
}
EOF
}
