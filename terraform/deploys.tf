// KubeDNS (SkyDNS) for cluster config
data "template_file" "deploy_base_kubedns" {
  template = "${file("terraform/templates/deploy_base_kubedns.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Kube Dashboard for cluster config
data "template_file" "deploy_base_dashboard" {
  template = "${file("terraform/templates/deploy_base_dashboard.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Kube EFS Storage Claim config
data "template_file" "deploy_base_efs_storageclaim" {
  template = "${file("terraform/templates/deploy_base_efs_storageclaim.yaml")}"

  vars {
    aws_region         = "${data.terraform_remote_state.vpc.vpc_region}"
    kube_efs_id        = "${aws_efs_file_system.kube_efs.id}"
    kube_efs_dns       = "${aws_efs_file_system.kube_efs.dns_name}"

    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Kube Ingress Controller (Nginx)
data "template_file" "deploy_base_ingress_controller" {
  template = "${file("terraform/templates/deploy_base_ingress_controller.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Demo Deployment+Service Nginx
data "template_file" "deploy_demo_nginx" {
  template = "${file("terraform/templates/deploy_demo_nginx.yaml")}"

  vars {
    dns_domain_public  = "${var.dns_domain_public}"
    url_public         = "${var.dns_urls["url_public"]}"

    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_system   = "${var.kubernetes["namespace_system"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Demo Deployment+Kube-Ingress-AWS Nginx
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

// Demo LetsEncrypt
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
    url_letsencrypt    = "${var.dns_urls["url_letsencrypt"]}"
    letsencrypt_email  = "${var.kubernetes["letsencrypt_email"]}"
    letsencrypt_secret = "${var.kubernetes["letsencrypt_secret"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

resource "null_resource" "render_deploys" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to deploy templates triggers regeneration
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_kubedns.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_dashboard.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_efs_storageclaim.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_ingress_controller.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_nginx.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_ingress_aws.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_demo_letsencrypt.yaml"))}"
  }
  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p deploys" }
  // Render deploy templates to file
  provisioner "local-exec" { command = "cat > deploys/deploy_base_kubedns.yaml <<EOL\n${data.template_file.deploy_base_kubedns.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_dashboard.yaml <<EOL\n${data.template_file.deploy_base_dashboard.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_efs_storageclaim.yaml <<EOL\n${data.template_file.deploy_base_efs_storageclaim.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_ingress_controller.yaml <<EOL\n${data.template_file.deploy_base_ingress_controller.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_nginx.yaml <<EOL\n${data.template_file.deploy_demo_nginx.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_ingress_aws.yaml <<EOL\n${data.template_file.deploy_demo_ingress_aws.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_letsencrypt.yaml <<EOL\n${data.template_file.deploy_demo_letsencrypt.rendered}\nEOL" }
}

// Outputs
output "__post_deploy_config_1st" {
  value = "deploy kubedns using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_kubedns.yaml"
}

output "__post_deploy_config_2nd" {
  value = "deploy dashboard using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_dashboard.yaml"
}

output "__post_deploy_config_3rd" {
  value = "deploy EFS storage using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_efs_storageclaim.yaml"
}

output "__post_deploy_config_4th" {
  value = "deploy nginx demo using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_ingress_controller.yaml"
}

# output "__post_deploy_config_5th_ADVANCED" {
#   value = "deploy Kube BASE using: ansible-playbook ../deploy-kube-base/scripts/deploy-base.yaml"
# }
