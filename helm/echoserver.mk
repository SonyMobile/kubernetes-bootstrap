.PHONY: deploy-app-echoserver
echoserver_CHARTVALUES = ingress.hosts[0]=echoserver.$(CLUSTER_FQDN)
deploy-app-echoserver: helm-package-install-echoserver ## Deploys or upgrades the echoserver application to the Kubernetes cluster.
