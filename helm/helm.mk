.PHONY: deploy-helm
deploy-helm: checkenv-$(ENVIRONMENT) ## Installs or upgrades helm.
	kubectl create -f helm/rbac-config.yaml || kubectl replace -f helm/rbac-config.yaml
	helm --kube-context $(CLUSTER_FQDN) init --service-account tiller --upgrade --wait


# Packages a helm chart for local installation.
#
package-%: $(OUTDIR)
	$(eval $*_package_file:=$(shell helm package helm/$* -d $(OUTDIR) | \
	  sed -e 's/Successfully packaged chart and saved it to: \(.*\)$$/\1/g'))
	@if [ -z "$($*_package_file)" ] ; then \
	  echo "error: Failed to package chart!"; exit 2; \
	else \
	  echo "Wrote package: $($*_package_file)" ; \
	fi

# Installs a locally packaged helm chart.
#
helm-package-install-%: checkenv-$(ENVIRONMENT) package-%
	helm $(VERBOSITY) --kube-context $(CLUSTER_FQDN) \
	  upgrade $(DRYRUN) --install $(ENVIRONMENT)-$* \
	  --set "aws_account_id=$(AWS_ACCOUNT_ID),base_fqdn=$(BASE_FQDN),cluster_fqdn=$(CLUSTER_FQDN)" \
	  $(if $($*_CHARTVALUES),--set $($*_CHARTVALUES),) \
	  $(subst ./,--values ./,$(wildcard ./helm/$*/values-$(ENVIRONMENT).yaml)) \
	  "$($*_package_file)"

# Installs a remotely packaged helm chart.
# It can be used for charts that aren't available in a Helm repository.
#
helm-remote-package-install-%: checkenv-$(ENVIRONMENT)
	helm $(VERBOSITY) --kube-context $(CLUSTER_FQDN) \
	  upgrade $(DRYRUN) --install $(ENVIRONMENT)-$* \
	  --set "aws_account_id=$(AWS_ACCOUNT_ID),base_fqdn=$(BASE_FQDN),cluster_fqdn=$(CLUSTER_FQDN)" \
	  $(subst ./,--values ./,$(wildcard ./helm/$*/values.yaml)) \
	  $(subst ./,--values ./,$(wildcard ./helm/$*/values-$(ENVIRONMENT).yaml)) \
	  $($*_URL)

# Installs a chart from the public helm stable repository.
# (https://github.com/helm/charts/tree/master/stable)
#
helm-stable-install-%: checkenv-$(ENVIRONMENT)
	helm repo update
	helm $(VERBOSITY) --kube-context $(CLUSTER_FQDN) upgrade --install $(DRYRUN) \
	  $(ENVIRONMENT)-$* stable/$* \
	  $(if $($*_CHARTVALUES),--set $($*_CHARTVALUES),) \
	  $(subst ./,--values ./,$(wildcard ./helm/$*/values.yaml)) \
	  $(subst ./,--values ./,$(wildcard ./helm/$*/values-$(ENVIRONMENT).yaml)) \
	  --version $($*_CHARTVER)
