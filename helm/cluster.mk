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
