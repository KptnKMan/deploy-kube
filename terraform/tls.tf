// This file includes (In order):
// -Generation of kubeconfig for admin access
// -Generation of all certs
// -Upload of certs to S3
// -Rendering of Certs to local disk

// Template for generated local kubeconfig file
data "template_file" "kubeconfig_admin" {
  template = "${file("terraform/templates/kubeconfig_generic.template")}"

  vars {
    key_type               = "admin"
    elb_name               = "${aws_elb.kubernetes_api_elb.dns_name}"
    cluster_name_short     = "${var.cluster_name_short}"
    cluster_domain         = "${var.kubernetes["cluster_domain"]}"
    api_server_secure_port = "${var.kubernetes["api_server_secure_port"]}"
    path_module            = "${data.terraform_remote_state.vpc.path_module}"
  }
}

// This null resource is used to generate/regenerate kubeconfig locally
// This is in case of changing ELB endpoint
resource "null_resource" "kubeconfig_admin" {
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // Any change to kubeconfig file triggers
    policy_sha1 = "${sha1(file("terraform/templates/kubeconfig_generic.template"))}"
    // uuid of api_elb
    "uuid()" = "${aws_elb.kubernetes_api_elb.id}"
  }
  // Generate kubeconfig template
  provisioner "local-exec" { command = "cat > config/kubeconfig <<EOL\n${data.template_file.kubeconfig_admin.rendered}\nEOL" }
}

// Generate root_ca
resource "tls_private_key" "root_ca" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate root_ca x509_CERT
resource "tls_self_signed_cert" "root_ca" {
  is_ca_certificate = true

  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.root_ca.private_key_pem}"

  subject {
    common_name  = "kubernetes"
    organization = "kubernetes"
    organizational_unit = "ops"
    street_address = ["street"]
    locality = "amsterdam"
    province = "noord-holland"
    country = "NL"
  }

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "server_auth",
    "client_auth",
  ]

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.kubernetes["cluster_domain"]}",
    "${var.dns_urls["url_admiral"]}.${var.dns_domain_public}",
    "${aws_elb.kubernetes_api_elb.dns_name}",
    "${aws_elb.kubernetes_api_elb_internal.dns_name}",
    "${var.cluster_name_short}",
    "*.${var.dns_domain_public}",
    "*.${var.aws_region}.compute.internal",
    "*.${var.aws_region}.compute.amazonaws.com",
    "*.${var.aws_region}.elb.amazonaws.com"
  ]

  ip_addresses = [
    "127.0.0.1", 
    "${var.kubernetes["service_ip"]}"
  ]
}

// Generate etcd_server_key
resource "tls_private_key" "etcd_server_key" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate etcd_server_key CSR_REQ
resource "tls_cert_request" "etcd_server_key" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.etcd_server_key.private_key_pem}"

  subject {
    common_name  = "kubernetes"
    organization = "kubernetes"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.kubernetes["cluster_domain"]}",
    "${var.dns_urls["url_etcd"]}.${var.dns_domain_public}",
    "${aws_elb.etcd_elb.dns_name}",
    "${var.cluster_name_short}",
    "*.${var.dns_domain_public}",
    "*.${var.aws_region}.compute.internal",
    "*.${var.aws_region}.compute.amazonaws.com",
    "*.${var.aws_region}.elb.amazonaws.com"
  ]

  ip_addresses = [
    "127.0.0.1", 
    "${var.kubernetes["service_ip"]}"
  ]
}

// Generate etcd_server_key x509_CERT
resource "tls_locally_signed_cert" "etcd_server_key" {
  cert_request_pem   = "${tls_cert_request.etcd_server_key.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.root_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root_ca.cert_pem}"

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel"
  ]
}

// Generate api_server_key
resource "tls_private_key" "api_server_key" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate api_server_key CSR_REQ
resource "tls_cert_request" "api_server_key" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.api_server_key.private_key_pem}"

  subject {
    common_name  = "kubernetes"
    organization = "kubernetes"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.kubernetes["cluster_domain"]}",
    "${var.dns_urls["url_admiral"]}.${var.dns_domain_public}",
    "${aws_elb.kubernetes_api_elb.dns_name}",
    "${aws_elb.kubernetes_api_elb_internal.dns_name}",
    "${var.cluster_name_short}",
    "*.${var.dns_domain_public}",
    "*.${var.aws_region}.compute.internal",
    "*.${var.aws_region}.compute.amazonaws.com",
    "*.${var.aws_region}.elb.amazonaws.com"
  ]

  ip_addresses = [
    "127.0.0.1", 
    "${var.kubernetes["service_ip"]}"
  ]
}

// Generate api_server_key x509_CERT
resource "tls_locally_signed_cert" "api_server_key" {
  cert_request_pem   = "${tls_cert_request.api_server_key.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.root_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root_ca.cert_pem}"

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel"
  ]
}

// Generate Cluster Administrator Keypair
resource "tls_private_key" "admin_key" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate admin_key CSR_REQ
resource "tls_cert_request" "admin_key" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.admin_key.private_key_pem}"

  subject {
    common_name  = "admin"
    organization = "system:masters"
    locality = "amsterdam"
    province = "noord-holland"
    country = "NL"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.kubernetes["cluster_domain"]}",
    "${var.dns_urls["url_admiral"]}.${var.dns_domain_public}",
    "${aws_elb.kubernetes_api_elb.dns_name}",
    "${aws_elb.kubernetes_api_elb_internal.dns_name}",
    "${var.cluster_name_short}",
    "*.${var.dns_domain_public}",
    "*.${var.aws_region}.compute.internal",
    "*.${var.aws_region}.compute.amazonaws.com",
    "*.${var.aws_region}.elb.amazonaws.com"
  ]

  ip_addresses = [
    "127.0.0.1", 
    "${var.kubernetes["service_ip"]}"
  ]
}

// Generate admin_key x509_CERT
resource "tls_locally_signed_cert" "admin_key" {
  cert_request_pem   = "${tls_cert_request.admin_key.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.root_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root_ca.cert_pem}"

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel"
  ]
}

// Generate Cluster Worker Keypair
resource "tls_private_key" "worker_key" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate worker_key CSR_REQ
resource "tls_cert_request" "worker_key" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.worker_key.private_key_pem}"

  subject {
    common_name  = "system:node:worker"
    organization = "system:nodes"
    locality = "amsterdam"
    province = "noord-holland"
    country = "NL"
  }

  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.kubernetes["cluster_domain"]}",
    "${aws_elb.kubernetes_api_elb.dns_name}",
    "${aws_elb.kubernetes_api_elb_internal.dns_name}",
    "${var.cluster_name_short}",
    "*.${var.dns_domain_public}",
    "*.${var.aws_region}.compute.internal",
    "*.${var.aws_region}.compute.amazonaws.com",
    "*.${var.aws_region}.elb.amazonaws.com"
  ]

  ip_addresses = [
    "127.0.0.1", 
    "${var.kubernetes["service_ip"]}"
  ]
}

// Generate worker_key x509_CERT
resource "tls_locally_signed_cert" "worker_key" {
  cert_request_pem   = "${tls_cert_request.worker_key.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.root_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root_ca.cert_pem}"

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel"
  ]
}

// Generate Cluster Dashboard Keypair
resource "tls_private_key" "dashboard" {
  algorithm   = "RSA"
  rsa_bits    = "2048"
}

// Generate dashboard CSR_REQ
resource "tls_cert_request" "dashboard" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.dashboard.private_key_pem}"

  subject {
    common_name  = "kube-admin"
  }
}

// Generate dashboard x509_CERT
resource "tls_locally_signed_cert" "dashboard" {
  cert_request_pem   = "${tls_cert_request.dashboard.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.root_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root_ca.cert_pem}"

  // valid for 1 year
  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "content_commitment",
    "key_encipherment",
    "data_encipherment",
    "key_agreement",
    "cert_signing",
    "crl_signing",
    "encipher_only",
    "decipher_only",
    "any_extended",
    "server_auth",
    "client_auth",
    "code_signing",
    "email_protection",
    "ipsec_end_system",
    "ipsec_tunnel"
  ]
}

// S3 Upload root_ca_keys
resource "aws_s3_bucket_object" "ca_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/ca.key"
  # source = "../config/ssl/ca.key"
  content = "${tls_private_key.root_ca.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "ca_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/ca.pem"
  # source = "../config/ssl/ca.pem"
  content = "${tls_self_signed_cert.root_ca.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// S3 Upload etcd_server_keys
resource "aws_s3_bucket_object" "etcdserver_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/etcdserver.key"
  # source = "../config/ssl/admin.key"
  content = "${tls_private_key.etcd_server_key.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "etcdserver_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/etcdserver.pem"
  # source = "../config/ssl/admin.pem"
  content = "${tls_locally_signed_cert.etcd_server_key.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// S3 Upload api_server_keys
resource "aws_s3_bucket_object" "apiserver_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/apiserver.key"
  # source = "../config/ssl/admin.key"
  content = "${tls_private_key.api_server_key.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "apiserver_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/apiserver.pem"
  # source = "../config/ssl/admin.pem"
  content = "${tls_locally_signed_cert.api_server_key.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// S3 Upload admin_keys
resource "aws_s3_bucket_object" "admin_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/admin.key"
  # source = "../config/ssl/admin.key"
  content = "${tls_private_key.admin_key.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "admin_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/admin.pem"
  # source = "../config/ssl/admin.pem"
  content = "${tls_locally_signed_cert.admin_key.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// S3 Upload worker_keys
resource "aws_s3_bucket_object" "worker_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/worker.key"
  # source = "../config/ssl/worker.key"
  content = "${tls_private_key.worker_key.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "worker_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/worker.pem"
  # source = "../config/ssl/worker.pem"
  content = "${tls_locally_signed_cert.worker_key.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// S3 Upload dashboard_keys
resource "aws_s3_bucket_object" "dashboard_key" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/dashboard.key"
  # source = "../config/ssl/dashboard.key"
  content = "${tls_private_key.dashboard.private_key_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}
resource "aws_s3_bucket_object" "dashboard_cert" {
  bucket = "${aws_s3_bucket.state_bucket.id}"
  key    = "ssl/dashboard.pem"
  # source = "../config/ssl/dashboard.pem"
  content = "${tls_locally_signed_cert.worker_key.cert_pem}"
  # etag   = "${md5(file("path/to/file"))}"
}

// Render all certs to disk
resource "null_resource" "render_certs" {
  depends_on = ["aws_s3_bucket.state_bucket"]
  triggers  = {
    // Any change to UUID (every apply) triggers re-provisioning
    # filename = "test-${uuid()}"
    // uuid of root_ca
    "uuid()" = "${tls_private_key.root_ca.id}",
    // Any change to root_ca file triggers
    # filename = "config/ssl/ca.key"
  }

  // Create dir for certs
  provisioner "local-exec" { command = "mkdir -p config/ssl" }

  // Render cluster root_ca
  provisioner "local-exec" { command = "cat > config/ssl/ca.key <<EOL\n${tls_private_key.root_ca.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/ca.pem <<EOL\n${tls_self_signed_cert.root_ca.cert_pem}\nEOL" }

  // Render etcd_server_key
  provisioner "local-exec" { command = "cat > config/ssl/etcdserver.key <<EOL\n${tls_private_key.etcd_server_key.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/etcdserver.csr <<EOL\n${tls_cert_request.etcd_server_key.cert_request_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/etcdserver.pem <<EOL\n${tls_locally_signed_cert.etcd_server_key.cert_pem}\nEOL" }

  // Render api_server_key
  provisioner "local-exec" { command = "cat > config/ssl/apiserver.key <<EOL\n${tls_private_key.api_server_key.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/apiserver.csr <<EOL\n${tls_cert_request.api_server_key.cert_request_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/apiserver.pem <<EOL\n${tls_locally_signed_cert.api_server_key.cert_pem}\nEOL" }

  // Render admin_key
  provisioner "local-exec" { command = "cat > config/ssl/admin.key <<EOL\n${tls_private_key.admin_key.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/admin.csr <<EOL\n${tls_cert_request.admin_key.cert_request_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/admin.pem <<EOL\n${tls_locally_signed_cert.admin_key.cert_pem}\nEOL" }

  // Render worker_key
  provisioner "local-exec" { command = "cat > config/ssl/worker.key <<EOL\n${tls_private_key.worker_key.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/worker.csr <<EOL\n${tls_cert_request.worker_key.cert_request_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/worker.pem <<EOL\n${tls_locally_signed_cert.worker_key.cert_pem}\nEOL" }

  // Render dashboard_key
  provisioner "local-exec" { command = "cat > config/ssl/dashboard.key <<EOL\n${tls_private_key.dashboard.private_key_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/dashboard.csr <<EOL\n${tls_cert_request.dashboard.cert_request_pem}\nEOL" }
  provisioner "local-exec" { command = "cat > config/ssl/dashboard.pem <<EOL\n${tls_locally_signed_cert.dashboard.cert_pem}\nEOL" }
  
  // Wait a few seconds
  provisioner "local-exec" { command = "echo waiting 5 seconds && sleep 5" }
}