// CONFIGURE ROUTE53 DNS ZONE
# Zone is configured in root template

// Primary www

resource "aws_route53_record" "public" {
  zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
  name    = "${var.dns_urls["url_public"]}"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.dns_urls["url_public"]}"
  records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
}

// PROD URLs

// OPS/MGMT URLs

resource "aws_route53_record" "etcd" {
  zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
  name    = "${var.dns_urls["url_etcd"]}"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.dns_urls["url_etcd"]}"
  records        = ["${aws_elb.etcd_elb.dns_name}"]
}

## clustername-admiral.mydomain.com
resource "aws_route53_record" "admiral" {
  zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
  name    = "${var.dns_urls["url_admiral"]}"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.dns_urls["url_admiral"]}"
  records        = ["${aws_elb.kubernetes_api_elb_public.dns_name}"]
}

## clustername-etcd.mydomain.com

// Outputs
output "_connect_bastion_r53" {
  value = "${data.terraform_remote_state.vpc._connect_bastion_r53}"
}

output "aws_r53_dns_public" {
  value = "${aws_route53_record.public.fqdn}"
}

output "aws_r53_dns_admiral" {
  value = "${aws_route53_record.admiral.fqdn}"
}

output "aws_r53_dns_etcd" {
  value = "${aws_route53_record.etcd.fqdn}"
}