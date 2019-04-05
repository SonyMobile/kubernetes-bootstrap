terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.aws_region}"
  version = "~> 2.0"
}

resource "aws_s3_bucket" "kops_state_bucket" {
  bucket        = "${var.kops_state_store}"
  region        = "${var.aws_region}"
  force_destroy = true

  versioning {
    enabled = true
  }
}

data "aws_route53_zone" "parent_hosted_zone" {
  name = "${var.base_fqdn}."
}

resource "aws_route53_zone" "cluster_hosted_zone" {
  name          = "${var.cluster_fqdn}."
  force_destroy = true
}

resource "aws_route53_record" "cluster_ns_record" {
  zone_id = "${data.aws_route53_zone.parent_hosted_zone.zone_id}"
  name    = "${var.cluster_fqdn}."
  type    = "NS"
  ttl     = "300"

  records = [
    "${aws_route53_zone.cluster_hosted_zone.name_servers.0}",
    "${aws_route53_zone.cluster_hosted_zone.name_servers.1}",
    "${aws_route53_zone.cluster_hosted_zone.name_servers.2}",
    "${aws_route53_zone.cluster_hosted_zone.name_servers.3}",
  ]
}
