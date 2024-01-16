
# Cert-Manager artifacts

REPO_NAME := gmarcy

# Container image for webhook
#

IMAGE_NAME := homelab-cert-manager-webhook
IMAGE_TAG := latest

.PHONY: build
build:
	podman build -t "${REPO_NAME}/$(IMAGE_NAME):$(IMAGE_TAG)" .

# Helm charts for webhook and issuers
#

NAMESPACE := cert-manager

WEBHOOK_HELM_CHART := homelab-cert-manager-webhook
WEBHOOK_HELM_FILES := $(shell find deploy/homelab-cert-manager-webhook)
ISSUERS_HELM_CHART := homelab-letsencrypt-issuers
ISSUERS_HELM_FILES := $(shell find deploy/homelab-letsencrypt-issuers)

OUT := $(shell pwd)/_out

$(OUT):
	mkdir -p $@

.PHONY: clean
clean:
	rm -r $(OUT)

# When helm chart changes, we need to publish to the charts repo
#
# Ensure version is updated in Chart.yaml
# Run `make helm`
# Check and commit the results, including the tgz files
#
.PHONY: helm
helm: helm.webhook helm.issuers
	helm repo index ../$(REPO_NAME).github.io/helm-charts --url https://$(REPO_NAME).github.io/helm-charts --merge ../$(REPO_NAME).github.io/helm-charts/index.yaml

.PHONY: helm.webhook
helm.webhook: $(WEBHOOK_HELM_FILES)
	helm package deploy/$(WEBHOOK_HELM_CHART)/ -d ../$(REPO_NAME).github.io/helm-charts/

.PHONY: helm.issuers
helm.issuers: $(ISSUERS_HELM_FILES)
	helm package deploy/$(ISSUERS_HELM_CHART)/ -d ../$(REPO_NAME).github.io/helm-charts/

.PHONY: rendered-manifests
rendered-manifests: $(OUT)/webhook-rendered-manifest.yaml $(OUT)/issuers-rendered-manifest.yaml

$(OUT)/webhook-rendered-manifest.yaml: $(WEBHOOK_HELM_FILES) | $(OUT)
	helm template -n $(NAMESPACE) $(WEBHOOK_HELM_CHART) deploy/$(WEBHOOK_HELM_CHART) > $@

$(OUT)/issuers-rendered-manifest.yaml: $(ISSUERS_HELM_FILES) | $(OUT)
	helm template -n $(NAMESPACE) $(ISSUERS_HELM_CHART) deploy/$(ISSUERS_HELM_CHART) > $@
