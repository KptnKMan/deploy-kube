// This is used to setup demo resources.
// Delete this file for a clean cluster without demo resources

// Demo DNS URLs

## clustername-traefik.mydomain.com
resource "aws_route53_record" "traefik" {
  zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
  name    = "${var.dns_urls["url_traefik"]}"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.dns_urls["url_traefik"]}"
  records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
}

## clustername-whoamidemo.mydomain.com (Demo app)
resource "aws_route53_record" "whoamidemo" {
  zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
  name    = "${var.dns_urls["url_whoamidemo"]}"
  type    = "CNAME"
  ttl     = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "${var.dns_urls["url_whoamidemo"]}"
  records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
}

// Demo Deploy files

## Demo Deployment+Service Nginx
data "template_file" "deploy_demo_nginx" {
  template = "${file("terraform/templates/deploy_demo_nginx.yaml")}"

  vars {
    dns_domain_public  = "${var.dns_domain_public}"
    url_app            = "${var.dns_urls["url_public"]}"

    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

## Demo Deployment+Service Nginx
data "template_file" "deploy_demo_traefik_whoami_app" {
  template = "${file("terraform/templates/deploy_demo_traefik_whoami_app.yaml")}"

  vars {
    dns_domain_public  = "${var.dns_domain_public}"
    url_app            = "${var.dns_urls["url_whoamidemo"]}"

    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

## Demo Deployment+Kube-Ingress-AWS Nginx
data "template_file" "deploy_demo_ingress_aws" {
  template = "${file("terraform/templates/deploy_demo_ingress_aws.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

## Demo LetsEncrypt
data "template_file" "deploy_demo_letsencrypt" {
  template = "${file("terraform/templates/deploy_demo_letsencrypt.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    ingress_port_http  = "${var.kubernetes["ingress_port_http"]}"
    ingress_port_https = "${var.kubernetes["ingress_port_https"]}"

    domain             = "${var.dns_domain_public}"
    url_app            = "${var.dns_urls["url_letsencrypt"]}"
    letsencrypt_email  = "${var.kubernetes["letsencrypt_email"]}"
    letsencrypt_secret = "${var.kubernetes["letsencrypt_secret"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Demo Render files

resource "null_resource" "render_demo_deploys" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to deploy templates triggers regeneration
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_nginx.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_traefik_whoami_app.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_ingress_aws.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_letsencrypt.yaml"))}"
  }
  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p deploys" }
  // Render deploy templates to file
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_nginx.yaml <<EOL\n${data.template_file.deploy_demo_nginx.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_traefik_whoami_app.yaml <<EOL\n${data.template_file.deploy_demo_traefik_whoami_app.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_ingress_aws.yaml <<EOL\n${data.template_file.deploy_demo_ingress_aws.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_letsencrypt.yaml <<EOL\n${data.template_file.deploy_demo_letsencrypt.rendered}\nEOL" }
}

// Demo Outputs

output "__post_deploy_config_4th" {
  value = "deploy nginx demo using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_ingress_controller.yaml"
}

# output "__post_deploy_config_5th_ADVANCED" {
#   value = "deploy Kube BASE using: ansible-playbook ../deploy-kube-base/scripts/deploy-base.yaml"
# }
