// Security Group for controllers
resource "aws_security_group" "controller_sg" {
  name        = "${var.cluster_name_short}-sg-controllers"
  description = "cluster ${var.cluster_name_short} Controller traffic"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  lifecycle {
    ignore_changes = ["ingress","egress"]
  }

  // Allow API access for all systems and self (LB) for management ips
  ingress {
    from_port       = "${var.kubernetes["api_server_secure_port"]}"
    to_port         = "${var.kubernetes["api_server_secure_port"]}"
    protocol        = "tcp"
    self            = true
    security_groups = ["${data.terraform_remote_state.vpc.sg_id_common}","${aws_security_group.kubernetes_controllers_elb_sg.id}"]
  }

  // Allow all systems for flannel overlay networking
  ingress {
    from_port = "8285"
    to_port   = "8285"
    protocol  = "udp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.sg_id_common}"]
  }

  // Allow all systems for flannel overlay networking
  ingress {
    from_port = "8472"
    to_port   = "8472"
    protocol  = "udp"
    self      = true
    security_groups = ["${data.terraform_remote_state.vpc.sg_id_common}"]
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-sg-controllers"
    )
  )}"
}

// Cloud Config file to configure controller
data "template_file" "cloud_config_ubuntu_controller" {
  template = "${file("terraform/templates/cloud_config_ubuntu_controller.yaml")}"

  vars {
    docker_version     = "${var.kubernetes["docker_version"]}"
    kubernetes_version = "${var.kubernetes["kube_version"]}"
    flannel_version    = "${var.kubernetes["flannel_version"]}"
    etcd_version       = "${var.kubernetes["etcd_version"]}"

    service_ip         = "${var.kubernetes["service_ip"]}"
    service_ip_range   = "${var.kubernetes["service_ip_range"]}"
    cluster_cidr       = "${var.kubernetes["service_ip_range"]}"
    flannel_network    = "${var.kubernetes["flannel_network"]}"
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    api_server_secure_port = "${var.kubernetes["api_server_secure_port"]}"
    api_server_insecure_port = "${var.kubernetes["api_server_insecure_port"]}"
    etcd_endpoints     = "http://${aws_elb.etcd_elb.dns_name}:2379"

    kubernetes_api_elb = "${aws_elb.kubernetes_api_elb.dns_name}"
    kubernetes_api_elb_internal = "${aws_elb.kubernetes_api_elb_internal.dns_name}"

    apiserver_runtime  = "${var.kubernetes["apiserver_runtime"]}"
    authorization_mode = "${var.kubernetes["authorization_mode"]}"
    admission_control  = "${var.kubernetes["admission_control"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"

    # workaround because terraform wants to replace all variables in file
    FLANNEL_SUBNET     = "${replace("%{FLANNEL_SUBNET}", "%", "$")}"
    FLANNEL_MTU        = "${replace("%{FLANNEL_MTU}", "%", "$")}"
    NODE_FQDN          = "${replace("%{NODE_FQDN}", "%", "$")}"
    NODE_IP            = "${replace("%{NODE_IP}", "%", "$")}"

    instance_group     = "controllers"
  }
}

// Launch configuration for Kubernetes controller servers
resource "aws_launch_configuration" "controller_configuration" {
  name_prefix = "${var.cluster_name_short}-controller-"

  image_id             = "${data.terraform_remote_state.vpc.ami_id_ubuntu}"
  instance_type        = "${var.instance_types["controller"]}"
  iam_instance_profile = "${data.terraform_remote_state.vpc.iam_instance_profile}"

  spot_price           = "${var.instance_types["spot_max_bid"]}"

  key_name             = "${data.terraform_remote_state.vpc.key_pair_name}"

  user_data            = "${data.template_file.cloud_config_ubuntu_controller.rendered}"
  security_groups      = ["${data.terraform_remote_state.vpc.sg_id_common}", "${aws_security_group.controller_sg.id}"]

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
resource "aws_cloudformation_stack" "controller_group" {
  depends_on = ["aws_cloudformation_stack.etcd_group"]
  name = "${var.cluster_name_short}-cfnstack-controller"

  template_body = <<EOF
{
  "Resources": {
    "Controller${var.cluster_name_short}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "VPCZoneIdentifier": ["${join(",", data.terraform_remote_state.vpc.vpc_subnets_public)}"],
        "LaunchConfigurationName": "${aws_launch_configuration.controller_configuration.name}",
        "LoadBalancerNames": ["${aws_elb.kubernetes_api_elb.name}", "${aws_elb.kubernetes_api_elb_internal.name}"],
        "MinSize": "${var.instances["controller_min"]}",
        "MaxSize": "${var.instances["controller_max"]}",
        "TerminationPolicies": ["OldestLaunchConfiguration", "OldestInstance"],
        "Tags": [{
          "Key": "Name",
          "Value": "${var.cluster_name_short}-ec2-controller",
          "PropagateAtLaunch": "true"
        },{
          "Key": "kubernetes.io/cluster/${var.cluster_name_short}",
          "Value": "owned",
          "PropagateAtLaunch": "true"
        },{
          "Key": "KubernetesCluster",
          "Value": "${var.cluster_name_short}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Role",
          "Value": "${var.cluster_tags["Role"]}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Service",
          "Value": "${var.cluster_tags["Service"]}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Business-Unit",
          "Value": "${var.cluster_tags["Business-Unit"]}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Owner",
          "Value": "${var.cluster_tags["Owner"]}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Purpose",
          "Value": "${var.cluster_tags["Purpose"]}",
          "PropagateAtLaunch": "true"
        },{
          "Key": "Terraform",
          "Value": "True",
          "PropagateAtLaunch": "true"
        }]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MaxBatchSize": "1",
          "PauseTime": "${var.instance_types["controller_wait"]}"
        }
      }
    }
  }
}
EOF

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-cfnstack-controllers"
    )
  )}"
}

// Security Group for API Controller ELB
resource "aws_security_group" "kubernetes_controllers_elb_sg" {
  name        = "${var.cluster_name_short}-sg-elb-api"
  description = "cluster ${var.cluster_name_short} API ELB to API controllers traffic"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  # Allow access to controller from management ips and cluster itself
  ingress {
    from_port   = "${var.kubernetes["api_server_secure_port"]}"
    to_port     = "${var.kubernetes["api_server_secure_port"]}"
    protocol    = "tcp"
    cidr_blocks = [
      "${split(",", data.terraform_remote_state.vpc.management_ips)}",
    ]
  }

# Allow incoming HTTPS from management ips
  ingress {
    from_port   = "${var.kubernetes["api_server_secure_port"]}"
    to_port     = "${var.kubernetes["api_server_secure_port"]}"
    protocol    = "tcp"
    cidr_blocks = [
      "${split(",", data.terraform_remote_state.vpc.management_ips_personal)}"
    ]
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-sg-elb-api"
    )
  )}"
}

// Loadbalancer for controllers
resource "aws_elb" "kubernetes_api_elb" {
  name = "${var.cluster_name_short}-elb-api-public"

  subnets = ["${data.terraform_remote_state.vpc.vpc_subnets_public}"]

  idle_timeout = 3600

  listener {
    instance_port     = "${var.kubernetes["api_server_secure_port"]}"
    instance_protocol = "tcp"
    lb_port           = "${var.kubernetes["api_server_secure_port"]}"
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "SSL:${var.kubernetes["api_server_secure_port"]}"
    interval            = 10
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-elb-api-public"
    )
  )}"

  cross_zone_load_balancing = true
  security_groups           = ["${data.terraform_remote_state.vpc.sg_id_common}", "${aws_security_group.kubernetes_controllers_elb_sg.id}"]
}

// Internal loadbalancer for controllers
resource "aws_elb" "kubernetes_api_elb_internal" {
  name = "${var.cluster_name_short}-elb-api-internal"

  subnets = ["${data.terraform_remote_state.vpc.vpc_subnets_public}"]

  idle_timeout = 3600

  listener {
    instance_port     = "${var.kubernetes["api_server_secure_port"]}"
    instance_protocol = "tcp"
    lb_port           = "${var.kubernetes["api_server_secure_port"]}"
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "SSL:${var.kubernetes["api_server_secure_port"]}"
    interval            = 10
  }

  tags = "${merge(
    local.aws_tags,
    map(
      "Name", "${var.cluster_name_short}-elb-api-internal"
    )
  )}"

  internal                  = true
  cross_zone_load_balancing = true
  security_groups           = ["${data.terraform_remote_state.vpc.sg_id_common}","${aws_security_group.controller_sg.id}"]
}

// Outputs
output "_kube_connection_details" {
  value = "connect to api-server using: kubectl --kubeconfig config/kubeconfig get nodes"
}
output "_kube_deployed_version" {
  value = "kubernetes version being deployed: ${var.kubernetes["kube_version"]}"
}
output "_kube_deployed_docker_version" {
  value = "docker version being deployed: ${var.kubernetes["docker_version"]}"
}
