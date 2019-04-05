variable "aws_region" {
  description = "AWS region"
}

variable "kops_state_store" {
  description = "Name of the bucket in which kops should store its state"
}

variable "base_fqdn" {
  description = "The base DNS domain in which to create clusers"
}

variable "cluster_fqdn" {
  description = "Fully Qualified Domain Name of the Kubernetes cluster"
}
