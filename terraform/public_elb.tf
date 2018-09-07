// Security Group for Public Ingress ELB
resource "aws_security_group" "kubernetes_public_elb_sg" {
  name        = "${var.cluster_name_short}-kubernetes-public-elb"
  description = "Traffic from ELB to Kubernetes Workers"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

# Allow incoming HTTPS from public internet
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = [
      "${var.kubernetes["ingress_cidr_public"]}"
    ]
  }

# Allow incoming HTTP from public internet
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [
      "${var.kubernetes["ingress_cidr_public"]}"
    ]
  }

  // ELB access from cluster workers
  ingress {
    from_port = "${var.kubernetes["ingress_port_https"]}"
    to_port   = "${var.kubernetes["ingress_port_https"]}"
    protocol  = "udp"
    self      = true
    security_groups = ["${aws_security_group.worker_sg.id}"]
  }

  // ELB access from cluster workers
  ingress {
    from_port = "${var.kubernetes["ingress_port_http"]}"
    to_port   = "${var.kubernetes["ingress_port_http"]}"
    protocol  = "udp"
    self      = true
    security_groups = ["${aws_security_group.worker_sg.id}"]
  }

  tags {
    Name               = "${var.cluster_name_short}-sg-public-kubernetes-elb"
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

// Loadbalancer for Workers Public Ingress
resource "aws_elb" "kubernetes_public_elb" {
  name = "${var.cluster_name_short}-public-ingress"

  subnets = ["${data.terraform_remote_state.vpc.vpc_subnets_public}"]

  idle_timeout = 3600

  listener {
    instance_port     = "${var.kubernetes["ingress_port_https"]}"
    instance_protocol = "tcp"
    lb_port           = "443"
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = "${var.kubernetes["ingress_port_http"]}"
    instance_protocol = "tcp"
    lb_port           = "80"
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:${var.kubernetes["ingress_port_http"]}"
    interval            = 10
  }

  tags {
    Terraform          = "${var.cluster_tags["Terraform"]}"
  }

  cross_zone_load_balancing = true
  security_groups           = ["${data.terraform_remote_state.vpc.common_sg_id}", "${aws_security_group.kubernetes_public_elb_sg.id}"]
}