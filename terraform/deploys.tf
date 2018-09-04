// KubeDNS (SkyDNS) for cluster config
data "template_file" "deploy_kubedns" {
  template = "${file("terraform/templates/deploy_kubedns.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Kube Dashboard for cluster config
data "template_file" "deploy_dashboard" {
  template = "${file("terraform/templates/deploy_dashboard.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Demo Deployment+Service Nginx
data "template_file" "deploy_demo_nginx" {
  template = "${file("terraform/templates/deploy_demo_nginx.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_private  = "${var.kubernetes["namespace_private"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

// Demo Deployment+Ingress Nginx
data "template_file" "deploy_demo_ingress" {
  template = "${file("terraform/templates/deploy_demo_ingress.yaml")}"

  vars {
    cluster_dns        = "${var.kubernetes["cluster_dns"]}"
    cluster_domain     = "${var.kubernetes["cluster_domain"]}"
    namespace_public   = "${var.kubernetes["namespace_public"]}"
    namespace_private  = "${var.kubernetes["namespace_private"]}"

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
    namespace_private  = "${var.kubernetes["namespace_private"]}"

    cluster_name_short = "${var.cluster_name_short}"
    cluster_config_location = "${var.cluster_config_location}"
  }
}

resource "null_resource" "deploys" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to deploy templates triggers regeneration
    filename = "terraform/templates/deploy_kubedns.yaml"
    filename = "terraform/templates/deploy_dashboard.yaml"
    filename = "terraform/templates/deploy_demo_nginx.yaml"
    filename = "terraform/templates/deploy_demo_ingress.yaml"
    filename = "terraform/templates/deploy_demo_ingress_aws.yaml"
  }
  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p deploys" }
  // Generate deploy_kubedns.yaml and deploy_dashboard.yaml templates to file
  provisioner "local-exec" { command = "cat > deploys/deploy_kubedns.yaml <<EOL\n${data.template_file.deploy_kubedns.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_dashboard.yaml <<EOL\n${data.template_file.deploy_dashboard.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_nginx.yaml <<EOL\n${data.template_file.deploy_demo_nginx.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_ingress.yaml <<EOL\n${data.template_file.deploy_demo_ingress.rendered}\nEOL" }
  provisioner "local-exec" { command = "cat > deploys/deploy_demo_ingress_aws.yaml <<EOL\n${data.template_file.deploy_demo_ingress_aws.rendered}\nEOL" }
}

// Outputs
output "__post_deploy_config_1st" {
  value = "deploy kubedns using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_kubedns.yaml"
}

output "__post_deploy_config_2nd" {
  value = "deploy kubedns using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_dashboard.yaml"
}

output "__post_deploy_config_3rd" {
  value = "deploy nginx demo using: kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_nginx.yaml"
}

output "__post_deploy_config_4th_ADVANCED" {
  value = "deploy kubedns using: ansible-playbook ../deploy-kube-base/scripts/deploy-base.yaml"
}
