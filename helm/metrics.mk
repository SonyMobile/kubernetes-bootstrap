metrics-server_CHARTVER := 1.1.0
.PHONY: deploy-metrics-server
deploy-metrics-server: helm-stable-install-metrics-server ## Deploys or upgrades the metrics server.


prometheus_CHARTVER := 7.4.0
prometheus_CHARTVALUES = "server.ingress.hosts[0]=prometheus.$(CLUSTER_FQDN)"
.PHONY: deploy-prometheus
deploy-prometheus: helm-stable-install-prometheus ## Deploys or upgrades prometheus.


grafana_CHARTVER := 1.17.4
grafana_CHARTVALUES = ingress.hosts[0]=grafana.$(CLUSTER_FQDN),$\
	datasources.datasources\\.yaml.datasources[0].url=http://$(ENVIRONMENT)-prometheus-server
.PHONY: deploy-grafana
deploy-grafana: helm-stable-install-grafana ## Deploys or upgrades grafana.
