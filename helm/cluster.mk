# Copyright 2019 Sony Mobile Communications Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.PHONY: deploy-authenticator
deploy-authenticator: helm-package-install-aws-iam-authenticator ## Deploys or upgrades the aws-iam-authenticator.


kube2iam_CHARTVER := 0.9.0
.PHONY: deploy-kube2iam
deploy-kube2iam: helm-stable-install-kube2iam ## Deploys or upgrades kube2iam.


nginx-ingress_CHARTVER := 1.3.1
nginx-ingress_CHARTVALUES = "tcp.9090=default/$(ENVIRONMENT)-prometheus-server:9090"
.PHONY: deploy-nginx-ingress
deploy-nginx-ingress: helm-stable-install-nginx-ingress ## Deploys or upgrades the NGINX Ingress Controller.


external-dns_CHARTVER := 1.0.2
external-dns_CHARTVALUES = aws.region=$(AWS_REGION),$\
	domainFilters[0]=$(CLUSTER_FQDN),$\
	txtOwnerId=$(CLUSTER_FQDN)
.PHONY: deploy-external-dns
deploy-external-dns: helm-stable-install-external-dns ## Deploys or upgrades ExternalDNS.


cluster-autoscaler_CHARTVER := 0.7.0
cluster-autoscaler_CHARTVALUES = autoDiscovery.clusterName=$(CLUSTER_FQDN),$\
    awsRegion=$(AWS_REGION)
.PHONY: deploy-autoscaler
deploy-autoscaler: helm-stable-install-cluster-autoscaler ## Deploys or upgrades cluster autoscaler.
