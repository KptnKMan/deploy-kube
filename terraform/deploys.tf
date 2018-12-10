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

// CoreDNS for cluster config - CoreDNS is default in 1.13+
data "template_file" "deploy_base_coredns" {
  template = "${file("terraform/templates/deploy_base_coredns.yaml")}"

  vars {
    cluster_dns_ip     = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    reverse_cidrs      = "in-addr.arpa ip6.arpa"
    stubdomains        = ""
    federations        = ""
    upstreamnameserver = "/etc/resolv.conf"

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

resource "null_resource" "render_deploys" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to deploy templates triggers regeneration
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_kubedns.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_coredns.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_dashboard.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_efs_storageclaim.yaml"))}"
    policy_sha1 = "${sha1(file("terraform/templates/deploy_base_ingress_controller.yaml"))}"
  }
  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p deploys" }
  // Render deploy templates to file
  provisioner "local-exec" { command = "cat > deploys/deploy_base_kubedns.yaml <<EOL\n${data.template_file.deploy_base_kubedns.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_coredns.yaml <<EOL\n${data.template_file.deploy_base_coredns.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_dashboard.yaml <<EOL\n${data.template_file.deploy_base_dashboard.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_efs_storageclaim.yaml <<EOL\n${data.template_file.deploy_base_efs_storageclaim.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_base_ingress_controller.yaml <<EOL\n${data.template_file.deploy_base_ingress_controller.rendered}\nEOL" }
}

// Outputs
output "__post_deploy_config_1st" {
  value = "deploy kubedns or coredns!"
}

output "__post_deploy_config_2a" {
  value = "(OPTION 1) kubedns: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_kubedns.yaml"
}

output "__post_deploy_config_2b" {
  value = "(OPTION 2) coredns: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_coredns.yaml"
}

output "__post_deploy_config_3" {
  value = "dashboard: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_dashboard.yaml"
}

output "__post_deploy_config_4a" {
  value = "EFS-storage: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_efs_storageclaim.yaml"
}
