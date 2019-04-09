/*
 * Copyright 2019 Sony Mobile Communications Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

resource "aws_s3_bucket_object" "readme" {
  bucket = "${var.kops_state_store}"
  key    = "README"
  content = "This is the kops state bucket for the cluster ${var.cluster_fqdn}."
  depends_on = ["aws_s3_bucket.kops_state_bucket"]
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
