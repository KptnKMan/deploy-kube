// Deploy variables file
// Variables here override the default variables file
// Variables here are overriden by command line and ENV variables at runtime

// Set AWS region
aws_region              = "eu-west-1"

// Name of cluster, used for tagging
cluster_name            = "Kareem POC Deployment"

// Short name of cluster, used for naming and tagging
cluster_name_short      = "kareempoc"

// Bucket for etcd backups
s3_backup_bucket        = "kareempoc-backup"

//Bucket for cert storage and other state storage
s3_state_bucket         = "kareempoc-state"

// primary dns domain, aka route53 hosted zone / dns domain / etc
dns_domain_public       = "bifromedia.com"

// URL prefixes for cluster components
dns_urls = {
  url_public            = "*" # "kareempoc" # primary public alias
  url_admiral           = "kareempoc-admiral" # API server alias
  url_etcd              = "kareempoc-etcd" # ETCD cluster alias
  url_letsencrypt       = "kareempoc-sslmebaby" # for LetsEncrypt
  url_jenkins           = "kareempoc-jenkins" # Jenkins access alias <-- TBC
  url_core_analytics    = "kareempoc-analytics" # Analytics access alias <-- TBC
}

instance_types = {
  // instance sizes of ec2 instances - may require terraform taint of ASG to update
  controller            = "t3.small" // "m1.small" // "m4.large"
  etcd                  = "t3.small" // "m1.small" // "m4.large"
  worker                = "t3.small" // "m1.small" // "m4.2xlarge"

  // grace period in seconds to wait between cycling nodes in ASGs
  controller_wait       = "PT30S" // "PT160S"
  etcd_wait             = "PT300S" // "PT300S"
  worker_wait           = "PT30S" // "PT200S"

  // Not the spot price you pay all the time, but maximum bid
  spot_max_bid          = "7.2"
}

// ASG sizing
instances = {
  controller_min        = 1 # 1 // Do not modify
  controller_max        = 1 # 1 // Do not modify
  etcd_min              = 1 # 3 // Do not modify
  etcd_max              = 1 # 4 // Do not modify
  worker_min            = 1 # 3
  worker_max            = 1 # 5
}

kubernetes {
  // do not change these after cluster build
  // Docker_Version Notes: kube 1.7+ to support docker 1.12.x, kube 1.8+ to support 1.13.x
  // https://github.com/kubernetes/kubernetes/blob/release-1.10/test/e2e_node/jenkins/image-config.yaml
  docker_version        = "18.03.0" # 17.03.0 # 17.03.1 # 17.03.2 # 17.06.0 # 17.06.1 # 17.06.2
                                    # 17.09.0 # 17.09.1 # 17.12.0 # 17.12.1
                                    # 18.03.0 # 18.03.1 # 18.06.0
  kube_version          = "1.10.6" # 1.9.10 # 1.10.6 # 1.11.1
  flannel_version       = "0.10.0" # 0.5.5 # 0.6.2 # 0.7.1 # 0.8.0 # 0.9.1 # 0.10.0
  
  // do not change these after cluster build
  // ETCD version used for ETCDCTL installation
  etcd_version          = "3.2.24" # "3.2.20" # "3.2.24" # v3.3.9"
  etcd_elb_internal     = true # if the single ELB should be internal (true) or public (false)

  // do not change these after cluster build
  // supported API runtimes of api-server on master/controller - keep on 1 line
  apiserver_runtime     = "api/all=true" # "api/all=false,api/v1=true" # "extensions/v1beta1=true,extensions/v1beta1/networkpolicies=true,extensions/v1beta1/deployments=true,extensions/v1beta1/daemonsets=true,extensions/v1beta1/thirdpartyresources=true,batch/v2alpha1=true"
  authorization_mode    = "Node,RBAC,AlwaysAllow" #--authorization-mode=Node,RBAC,AlwaysAllow
  admission_control     = "AlwaysAdmit,NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota" #--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota

  // do not change these after cluster build
  // core parameters for Kubernetes networking
  flannel_network       = "10.200.0.0/16" # aka cluster-cidr / pod-network
  service_ip_range      = "10.5.0.0/24" # aka service-cluster-ip-range / service-network
  service_ip            = "10.5.0.1" # aka MASTER_CLUSTER_IP
  cluster_dns           = "10.5.0.10" # DNS server inside cluster (kube-dns)
  cluster_domain        = "kareempoc.local" # cluster domain, recommended to make a unique name for this.
  api_server_secure_port   = "6443" # Controllers API Server http port
  api_server_insecure_port = "8080" # Controllers API Server https port

  // Kubernetes deployment variables
  namespace_public      = "default" # default PUBLIC namespace that all services are deployed into (usually default or kube-public)
  namespace_private     = "default" # default PRIVATE namespace all services will be deployed into (usually default or kube-system)

  // Public facing ports for the default ingress
  ingress_port_http     = "32004" # port that cluster services expose, must be between 30000-32767
  ingress_port_https    = "32005" # port that cluster services expose, must be between 30000-32767
  public_elb_port_http  = "80" # port public ELB exposes to internet
  public_elb_port_https = "443" # port public ELB exposes to internet
  public_elb_cidr       = "0.0.0.0/0" # IP range public ELB exposes to internet, limit to "you.rpu.bli.cip/32" if you want only you.

  // Extra management IP - Leave blank or add full CIDR here (Eg: 1.1.1.1/1,2.2.2.2/2 comma separated, no spaces)
  letsencrypt_email     = "some.email@myemail.com" # Your email used for LetsEncrypt
  letsencrypt_secret    = "deez-certs" # Password used for LetsEncrypt
}

// Common Tags for all resources in deployment
cluster_tags = {
  Role                  = "Dev"
  Service               = "Base Infrastructure"
  Business-Unit         = "INFRE"
  Owner                 = "OpsEng"
  Purpose               = "Terraform Kubernetes Cluster"
}

// EFS storage for cluster backups and usage
efs_storage = {
  creation_token        = "kareempoc"
  performance_mode      = "generalPurpose" # "generalPurpose" or "maxIO"
  encrypted             = "true" # true or false
}
