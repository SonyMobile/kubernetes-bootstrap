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
