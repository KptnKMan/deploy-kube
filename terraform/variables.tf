variable "aws_access_key" {
  type                    = "string"
}

variable "aws_secret_key" {
  type                    = "string"
}

variable "aws_region" {
  type                    = "string"
  default                 = "eu-west-1"
}

variable "aws_availability_zones" {
  type                    = "list"
  default                 = ["eu-west-1a","eu-west-1b","eu-west-1c"]
}

# variable "key_name" {
  # type                    = "string"
  # default                 = "kareempoc"
# }

variable "cluster_name" {
  type                    = "string"
  default                 = "kareempoc"
}

variable "cluster_name_short" {
  type                    = "string"
  default                 = "kareempoc"
}

variable "s3_backup_bucket" {
  type                    = "string"
  default                 = "kareempoc-backup"
}

variable "s3_state_bucket" {
  type                    = "string"
  default                 = "kareempoc-state"
}

variable "dns_domain_public" {
  type                    = "string"
  default                 = "mydomain.com"
}

variable "dns_urls" {
  type = "map"

  default = {
    url_public            = "*"
    url_admiral           = "kareempoc-admiral"
    url_etcd              = "kareempoc-etcd"
    url_letsencrypt       = "kareempoc-sslmebaby"
    url_jenkins           = "kareempoc-jenkins"
    url_core_analytics    = "kareempoc-analytics"
  }
}

variable "instance_types" {
  default = {
    controller            = "m4.large"
    etcd                  = "m4.large"
    worker                = "m4.2xlarge"

    controller_wait       = "PT160S"
    etcd_wait             = "PT300S"
    worker_wait           = "PT200S"

    spot_max_bid          = "7.2"
  }
}

variable "instances" {
  type = "map"

  default = {
    controller_min        = 1
    controller_max        = 1
    etcd_min              = 3
    etcd_max              = 4
    worker_min            = 3
    worker_max            = 5
  }
}

variable "kubernetes" {
  default = {
    docker_version        = "18.3.0"
    kube_version          = "1.10.6"
    flannel_version       = "0.10.0"
    etcd_version          = "3.2.24"

    apiserver_runtime     = "api/all=true"
    authorization_mode    = "Node,RBAC,AlwaysAllow"
    admission_control     = "AlwaysAdmit,NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota"

    flannel_network       = "192.168.0.0/16"
    service_ip_range      = "10.5.0.0/24"
    service_ip            = "10.4.0.1"
    cluster_dns           = "10.4.0.10"
    cluster_domain        = "kubernetes.local"
    api_server_secure_port   = "6443"
    api_server_insecure_port = "8080"

    namespace_public      = "default"
    namespace_private     = "default"

    ingress_port_http     = "32004"
    ingress_port_https    = "32005"
    public_elb_port_http  = "80"
    public_elb_port_https = "443"
    public_elb_cidr       = "0.0.0.0/0"

    letsencrypt_email     = "some.email@myemail.com"
    letsencrypt_secret    = "deez-certs"
  }
}

variable "cluster_tags" {
  default = {
    Role                  = "Dev"
    Service               = "Base Infrastructure"
    Business-Unit         = "INFRE"
    Owner                 = "OpsEng"
    Purpose               = "Terraform Kubernetes Cluster"
  }
}

variable "efs_storage" {
  default = {
    creation_token        = "kareempoc"
    performance_mode      = "generalPurpose"
    encrypted             = "true"
  }
}

variable cluster_config_location {
  type                    = "string"
}
