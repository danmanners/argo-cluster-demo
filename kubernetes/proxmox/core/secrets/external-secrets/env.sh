HELM_APP_NAMESPACE=kube-system
HELM_REPO_NAME=sealed-secrets
HELM_REPO_SOURCE=https://bitnami-labs.github.io/sealed-secrets
HELM_APP_NAME=sealed-secrets
HELM_APP_VERSION=2.15.2
# renovate: datasource=github-releases depName=bitnami-labs/sealed-secrets
ADDITIONAL_INSTALL=https://raw.githubusercontent.com/bitnami-labs/sealed-secrets/release/v0.26.2/helm/sealed-secrets/crds/bitnami.com_sealedsecrets.yaml
