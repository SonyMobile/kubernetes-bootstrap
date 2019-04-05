-include environments.mk
-include helm/*.mk

AWS_REGION ?= eu-west-1
BASE_FQDN ?= example.com
ENVIRONMENT ?= lab

# The variables below are computed from those above and are not for customisation.
#
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --output text --query 'Account')
CLUSTER_FQDN = $(ENVIRONMENT).$(BASE_FQDN)
CLUSTER_SPEC = $(OUTDIR)/cluster.yaml
CLUSTER_SSH_KEY = $(OUTDIR)/ssh_key_$(ENVIRONMENT)
TERRAFORM_STATE_BUCKET = $(ENVIRONMENT)-tf-state
TERRAFORM_STATELOCK_TABLE = $(ENVIRONMENT)-tf-statelock
KOPS_STATE_BUCKET = $(ENVIRONMENT)-kops-state
KOPS = kops --state s3://$(KOPS_STATE_BUCKET)
OUTDIR = ./out

.PHONY: vars
vars:
	@echo export KOPS_STATE_STORE=s3://$(KOPS_STATE_BUCKET)
	@echo export CLUSTER_FQDN=$(CLUSTER_FQDN)

# A directory for intermediate outputs
#
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Ensure that the ENVIRONMENT variable match the expected AWS account and region.
# This protects against accidental deployment to the wrong account: i.e. we want to avoid deploying
# test infrastructure to the production account.
#
checkenv-%:
	$(call check_environment,$($*_aws_account),$($*_aws_region))

define check_environment
  @if [ -z "$(1)" -o -z "$(2)" ] ; then \
    echo "warning: Skipping AWS account and region check for $(ENVIRONMENT)"; \
  elif [ "$(AWS_ACCOUNT_ID)" != "$(1)" ] ; then \
    echo "error: Wrong AWS credentials activated!"; exit 2; \
  elif [ "$(AWS_DEFAULT_REGION)" != "$(2)" ] && \
       [ "$(AWS_REGION)" != "$(2)" ] && \
       [ "$(shell aws configure get region)" != "$(2)" ] ; then \
    echo "error: Wrong AWS region activated!"; exit 2; \
  else true; fi
endef


.PHONY: deploy-bootstrap
deploy-bootstrap: checkenv-$(ENVIRONMENT) ## Deploys the bootstrap Terraform stack.
	@echo "Deploying bootstrap to $(ENVIRONMENT)"
	( cd terraform/bootstrap ; terraform init && \
	  terraform apply -auto-approve \
	    -state $(ENVIRONMENT)-terraform.tfstate \
	    -var "aws_region=$(AWS_REGION)" \
	    -var "bucket=$(TERRAFORM_STATE_BUCKET)" \
	    -var "dynamodb_table=$(TERRAFORM_STATELOCK_TABLE)" )


.PHONY: clean-bootstrap
clean-bootstrap: checkenv-$(ENVIRONMENT) ## Removes the bootstrap resources.
	@echo "Destoying bootstrap on $(ENVIRONMENT)"
	( cd terraform/bootstrap ; terraform init && \
	  terraform destroy \
	    -state $(ENVIRONMENT)-terraform.tfstate \
	    -var "aws_region=$(AWS_REGION)" \
	    -var "bucket=$(TERRAFORM_STATE_BUCKET)" \
	    -var "dynamodb_table=$(TERRAFORM_STATELOCK_TABLE)" )


.PHONY: deploy-infra
deploy-infra: checkenv-$(ENVIRONMENT) ## Deploys the infrastructure required by kops in order to create a Kubernetes cluster.
	@echo "Deploying infra to $(ENVIRONMENT)"
	( cd terraform/infra ; \
	  terraform init \
	    -backend-config="region=$(AWS_REGION)" \
	    -backend-config="bucket=$(TERRAFORM_STATE_BUCKET)" \
	    -backend-config="key=$(ENVIRONMENT)-terrafrom.tfstate" \
	    -backend-config="dynamodb_table=$(TERRAFORM_STATELOCK_TABLE)" && \
	  terraform apply -auto-approve \
	    -var "aws_region=$(AWS_REGION)" \
	    -var "base_fqdn=$(BASE_FQDN)" \
	    -var "cluster_fqdn=$(CLUSTER_FQDN)" \
	    -var "kops_state_store=$(KOPS_STATE_BUCKET)" )


.PHONY: clean-infra
clean-infra: checkenv-$(ENVIRONMENT) ## Removes the infrastructure resources.
	@echo "Destroying infra on $(ENVIRONMENT)"
	( cd terraform/infra ; \
	  terraform init \
	    -backend-config="region=$(AWS_REGION)" \
	    -backend-config="bucket=$(TERRAFORM_STATE_BUCKET)" \
	    -backend-config="key=$(ENVIRONMENT)-terrafrom.tfstate" \
	    -backend-config="dynamodb_table=$(TERRAFORM_STATELOCK_TABLE)" && \
	  terraform destroy \
	    -var "aws_region=$(AWS_REGION)" \
	    -var "base_fqdn=$(BASE_FQDN)" \
	    -var "cluster_fqdn=$(CLUSTER_FQDN)" \
	    -var "kops_state_store=$(KOPS_STATE_BUCKET)" )


# Generates a cluster specification from a template
#
.PHONY: $(CLUSTER_SPEC)    # Even though this is a real file, we always want to overwrite it.
$(CLUSTER_SPEC): $(OUTDIR)
	$(KOPS) toolbox template --template kops/cluster.tpl.yaml \
	  --values kops/values.yaml \
	  $(subst ./,--values ./,$(wildcard ./kops/values-$(ENVIRONMENT).yaml)) \
	  --set "awsRegion=$(AWS_REGION),clusterFqdn=$(CLUSTER_FQDN),kopsStateStore=$(KOPS_STATE_BUCKET)" \
	  --output $(CLUSTER_SPEC)


.PHONY: deploy-cluster
deploy-cluster: checkenv-$(ENVIRONMENT) $(OUTDIR) $(CLUSTER_SPEC) ## Creates a new Kubernetes cluster using kops.
	@echo "Deploying cluster to $(ENVIRONMENT)"
	(cd $(OUTDIR) && aws-iam-authenticator init -i $(CLUSTER_FQDN))
	aws s3 cp $(OUTDIR)/cert.pem s3://$(KOPS_STATE_BUCKET)/$(CLUSTER_FQDN)/addons/authenticator/cert.pem
	aws s3 cp $(OUTDIR)/key.pem s3://$(KOPS_STATE_BUCKET)/$(CLUSTER_FQDN)/addons/authenticator/key.pem
	aws s3 cp $(OUTDIR)/aws-iam-authenticator.kubeconfig s3://$(KOPS_STATE_BUCKET)/$(CLUSTER_FQDN)/addons/authenticator/kubeconfig.yaml
	$(KOPS) create -f $(CLUSTER_SPEC)
	mkdir -p $(dir $(CLUSTER_SSH_KEY))
	ssh-keygen -t rsa -b 4096 -N "" -f $(CLUSTER_SSH_KEY)
	aws s3 cp $(CLUSTER_SSH_KEY) s3://$(KOPS_STATE_BUCKET)/ssh-keys/
	$(KOPS) --name $(CLUSTER_FQDN) create secret sshpublickey admin \
	  -i $(CLUSTER_SSH_KEY).pub
	$(KOPS) --name $(CLUSTER_FQDN) update cluster --yes


.PHONY: clean-cluster
clean-cluster: checkenv-$(ENVIRONMENT) ## Tears-down the Kubernetes cluster.
	@while [ "$$ans" != y -a "$$ans" != n ]; \
	do echo -n "Are you sure you want to destroy the cluster $(CLUSTER_FQDN)? [y/n] " && read ans; done; \
	if [ $$ans = n ] ; then \
	  echo "Aborting clean cluster"; exit 2; \
	else \
	  echo "Destroying $(CLUSTER_FQDN)..."; \
	  $(KOPS) --name $(CLUSTER_FQDN) delete cluster --yes; \
	  rm -rf $(OUTDIR); \
	fi


.PHONY: validate-cluster
validate-cluster: checkenv-$(ENVIRONMENT) ## Checks whether the Kubernetes cluster is ready for use.
	$(KOPS) --name $(CLUSTER_FQDN) validate cluster


.PHONY: update-cluster
update-cluster: checkenv-$(ENVIRONMENT) $(CLUSTER_SPEC) ## Updates a Kubernetes cluster from an updated cluster specification file.
	@echo "Updating cluster $(CLUSTER_FQDN)"
	$(KOPS) --name $(CLUSTER_FQDN) replace -f $(CLUSTER_SPEC)
	$(KOPS) --name $(CLUSTER_FQDN) update cluster --yes
	$(KOPS) --name $(CLUSTER_FQDN) rolling-update cluster --yes


.PHONY: export-kubecfg
export-kubecfg: checkenv-$(ENVIRONMENT) ## Export a kubecfg file for a cluster from the state store.
	$(KOPS) --name $(CLUSTER_FQDN) export kubecfg


#
# The parameterised targets and functions below support the concrete `deploy-app-...` targets above

VERBOSITY :=
.PHONY: verbose
verbose:
	$(eval VERBOSITY=--debug)
	@:

DRYRUN :=
.PHONY: dry-run
dry-run:
	$(eval DRYRUN=--dry-run)
	@:


.PHONY: help
help:
	@echo "Usage: make [verbose] [dry-run] <TARGET> where TARGET is one of below:"
	@grep -h -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

# Disable implicit and old fashioned suffix rules
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
