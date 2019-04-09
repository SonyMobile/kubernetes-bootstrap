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

.PHONY: deploy-app-echoserver
echoserver_CHARTVALUES = ingress.hosts[0]=echoserver.$(CLUSTER_FQDN)
deploy-app-echoserver: helm-package-install-echoserver ## Deploys or upgrades the echoserver application to the Kubernetes cluster.
