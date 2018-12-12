// Default variables file
// Variables here are used if no variable is set elsewhere
// Variables here are overriden by the deploy variables file

variable cluster_config_location {
  type                    = "string"
  default                 = "config"
}

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

variable "cluster_name" {
  type                    = "string"
  default                 = "Kareem POC Deployment"
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
}

variable "dns_urls" {
  type = "map"
  default = {
    wildcard              = "*"
    url_public            = "kareempoc-public"
    url_admiral           = "kareempoc-admiral"
    url_etcd              = "kareempoc-etcd"
    url_traefik           = "kareempoc-traefik"
    url_whoami_traefik    = "kareempoc-whoami-traefik"
    url_whoami_nginx      = "kareempoc-whoami-nginx"
    url_nginxdemo         = "kareempoc-nginxdemo"
    url_letsencrypt       = "kareempoc-sslmebaby"
    url_jenkins           = "kareempoc-jenkins"
    url_analytics         = "kareempoc-analytics"
  }
}

variable "instance_types" {
  type = "map"
  default = {
    controller            = "m3.medium"
    etcd                  = "m3.medium"
    worker                = "m3.medium"

    controller_wait       = "PT160S"
    etcd_wait             = "PT300S"
    worker_wait           = "PT200S"

    spot_max_bid          = "0.073"
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
  type = "map"
  default = {
    docker_version        = "18.03.1"
    kube_version          = "1.12.2"
    flannel_version       = "0.10.0"
    etcd_version          = "3.2.25"
    etcd_elb_internal     = true

    apiserver_runtime     = "api/all=true"
    authorization_mode    = "Node,RBAC,AlwaysAllow"
    admission_control     = "AlwaysAdmit,NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota"

    flannel_network       = "10.200.0.0/16"
    service_ip_range      = "10.5.0.0/24"
    service_ip            = "10.5.0.1"
    cluster_dns           = "10.5.0.10"
    cluster_domain        = "kareempoc.local"
    api_server_secure_port   = "6443"
    api_server_insecure_port = "8080"

    namespace_public      = "default"
    namespace_system      = "kube-system"

    ingress_port_http     = "32004"
    ingress_port_https    = "32005"
    public_elb_port_http  = "80"
    public_elb_port_https = "443"
    public_elb_cidr       = "0.0.0.0/0"

    letsencrypt_email     = "some.email@mydomain.com"
    letsencrypt_secret    = "get-deez-certs"
    letsencrypt_issuer    = "letsencrypt-staging"
  }
}

variable "cluster_tags" {
  type = "map"
  default = {
    Role                  = "Dev"
    Service               = "Base Infrastructure"
    Business-Unit         = "INFRE"
    Owner                 = "OpsEng"
    Purpose               = "Terraform Kubernetes Cluster"
  }
}

variable "efs_storage" {
  type = "map"
  default = {
    creation_token        = "kareempoc"
    performance_mode      = "generalPurpose"
    encrypted             = "true"
  }
}