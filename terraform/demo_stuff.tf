// Test to confirm Kube cluster to come up - WIP
# data "http" "kube_api_server" {
#   depends_on = ["aws_cloudformation_stack.etcd_group","aws_cloudformation_stack.controller_group","aws_cloudformation_stack.worker_group"]
#   url = "https://${aws_elb.kubernetes_api_elb_public.dns_name}:${var.kubernetes["api_server_secure_port"]}"

#   Optional request headers
#   request_headers {
#     "Accept" = "application/json"
#   }
# }

// This is used to setup demo resources.
// Delete this file for a clean cluster without demo resources

// Demo DNS URLs

// Note: custom DNS URLs are not required if a "*" is used as default public address.
//       In event of using "*", all URLs will be captured and sent to ingress.
//       In any other case, uncomment the below URLs for demo use.

## clustername-traefik.mydomain.com
# resource "aws_route53_record" "traefik" {
#   zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
#   name    = "${var.dns_urls["url_traefik"]}"
#   type    = "CNAME"
#   ttl     = "5"

#   weighted_routing_policy {
#     weight = 10
#   }

#   set_identifier = "${var.dns_urls["url_traefik"]}"
#   records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
# }

## clustername-whoami-traefik.mydomain.com (Demo app)
# resource "aws_route53_record" "whoami_traefik" {
#   zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
#   name    = "${var.dns_urls["url_whoami_traefik"]}"
#   type    = "CNAME"
#   ttl     = "5"

#   weighted_routing_policy {
#     weight = 10
#   }

#   set_identifier = "${var.dns_urls["url_whoami_traefik"]}"
#   records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
# }

## clustername-whoami-nginx.mydomain.com (Demo app)
# resource "aws_route53_record" "whoami_nginx" {
#   zone_id = "${data.terraform_remote_state.vpc.route53_zone_id}"
#   name    = "${var.dns_urls["url_whoami_nginx"]}"
#   type    = "CNAME"
#   ttl     = "5"

#   weighted_routing_policy {
#     weight = 10
#   }

#   set_identifier = "${var.dns_urls["url_whoami_nginx"]}"
#   records        = ["${aws_elb.kubernetes_public_elb.dns_name}"]
# }

// Demo Deploy files

## Demo Deployment+Service Nginx
data "template_file" "deploy_demo_nginx" {
  template = "${file("terraform/templates/deploy_demo_nginx.yaml")}"

  vars {
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"
    url_app            = "${var.dns_urls["url_public"]}"
    dns_domain_public  = "${var.dns_domain_public}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
  }
}

## Demo WHOAMI Deployment+Service Nginx
data "template_file" "deploy_demo_whoami_app" {
  template = "${file("terraform/templates/deploy_demo_whoami_app.yaml")}"

  vars {
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"
    letsencrypt_issuer = "${var.kubernetes["letsencrypt_issuer"]}"
    url_app_traefik    = "${var.dns_urls["url_whoami_traefik"]}"
    url_app_nginx      = "${var.dns_urls["url_whoami_nginx"]}"
    url_public         = "${var.dns_urls["url_public"]}"
    url_wildcard       = "${var.dns_urls["wildcard"]}"
    dns_domain_public  = "${var.dns_domain_public}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
  }
}

## Demo Issuer YAML for Cert Manager (LetsEncrypt)
data "template_file" "deploy_demo_certmgr_issuer" {
  template = "${file("terraform/templates/deploy_demo_certmgr_issuer.yaml")}"

  vars {
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"
    letsencrypt_email  = "${var.kubernetes["letsencrypt_email"]}"
    letsencrypt_secret = "${var.kubernetes["letsencrypt_secret"]}"
    aws_region         = "${var.aws_region}"
    aws_r53_zone_id    = "${data.terraform_remote_state.vpc.route53_zone_id}"
  }
}

## Demo Cert Request YAML for Cert Manager (LetsEncrypt)
data "template_file" "deploy_demo_certmgr_certreq" {
  template = "${file("terraform/templates/deploy_demo_certmgr_certreq.yaml")}"

  vars {
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"
    letsencrypt_issuer = "${var.kubernetes["letsencrypt_issuer"]}"
    url_app            = "${var.dns_urls["url_public"]}"
    url_wildcard       = "${var.dns_urls["wildcard"]}"
    dns_domain_public  = "${var.dns_domain_public}"
  }
}

// Demo Render files

resource "null_resource" "render_demo_deploys" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to deploy templates triggers regeneration
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_nginx.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_whoami_app.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_certmgr_issuer.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_certmgr_certreq.yaml"))}"
  }
  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p deploys" }
  // Render deploy templates to file
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_nginx.yaml <<EOL\n${data.template_file.deploy_demo_nginx.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_whoami_app.yaml <<EOL\n${data.template_file.deploy_demo_whoami_app.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_certmgr_issuer.yaml <<EOL\n${data.template_file.deploy_demo_certmgr_issuer.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_certmgr_certreq.yaml <<EOL\n${data.template_file.deploy_demo_certmgr_certreq.rendered}\nEOL" }
}

// Demo Outputs

# output "__post_deploy_config_4th" {
#   value = "deploy nginx demo using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_ingress_controller.yaml"
# }

output "__post_deploy_config_4b" {
  value = "helm: helm init"
}

output "__post_deploy_config_5a" {
  value = "ingress-demo-app: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_whoami_app.yaml"
}

output "__post_deploy_config_5b" {
  value = "(OPTION 1) traefik ingress: helm install stable/traefik --name traefik-ingress --namespace ${var.kubernetes["namespace_system"]} --set imageTag=1.7.4,dashboard.enabled=true,dashboard.domain=${var.dns_urls["url_traefik"]}.${var.dns_domain_public},service.nodePorts.http=${var.kubernetes["ingress_port_http"]},service.nodePorts.https=${var.kubernetes["ingress_port_https"]},serviceType=NodePort,ssl.enabled=true,ssl.enforced=false,acme.enabled=true,acme.challengeType=dns-01,acme.dnsProvider.name=route53,acme.email=${var.kubernetes["letsencrypt_email"]},acme.staging=true,acme.logging=enabled,acme.domains.enabled=true,acme.domains.domainList.main=${var.dns_urls["url_public"]}.${var.dns_domain_public},acme.domains.domainList.sans=${var.dns_domain_public},acme.persistence.enabled=false"
}

output "__post_deploy_config_5c" {
  value = "(OPTION 2) nginx ingress: helm install stable/nginx-ingress --name nginx-ingress --namespace ${var.kubernetes["namespace_system"]} --set image.tag=0.20.0,controller.service.type=NodePort,controller.service.nodePorts.http=${var.kubernetes["ingress_port_http"]},controller.service.nodePorts.https=${var.kubernetes["ingress_port_https"]},ServiceAccount.Create=true,rbac.create=true"
}

# the following additional helm "set" options can be added, but not required:
# ingressShim.defaultIssuerName=${var.kubernetes["letsencrypt_issuer"]},ingressShim.defaultIssuerKind=ClusterIssuer
# Helm chart Cert-Manager 0.4.1 is used as there is a bug in current 0.5.2 for wildcard certs over AWS ELBs
# https://github.com/jetstack/cert-manager/issues/837
# https://github.com/jetstack/cert-manager/pull/670
# https://github.com/jetstack/cert-manager/pull/750
# https://github.com/jetstack/cert-manager/issues/760
output "__post_deploy_config_6a" {
  value = "(OPTION 2) cert-mgr: helm install stable/cert-manager --name cert-manager --namespace ${var.kubernetes["namespace_system"]} --set image.tag=v0.4.1,rbac.create=true,serviceAccount.create=true"
}

output "__post_deploy_config_6b" {
  value = "(OPTION 2) cert-manager issuer: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_certmgr_issuer.yaml"
}

output "__post_deploy_config_6c" {
  value = "(OPTION 2) cert-manager certreq: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_certmgr_certreq.yaml"
}

# output "__post_deploy_config_5th_ADVANCED" {
#   value = "Kube BASE: ansible-playbook ../deploy-kube-base/scripts/deploy-base.yaml"
# }