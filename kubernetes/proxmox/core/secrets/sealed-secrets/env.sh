HELM_APP_NAMESPACE=secrets
HELM_REPO_NAME=external-secrets
HELM_REPO_SOURCE=https://charts.external-secrets.io
HELM_APP_NAME=external-secrets
HELM_APP_VERSION=0.9.14
ADDITIONAL_KUSTOMIZE=kubernetes/proxmox/core/secrets/sealed-secrets,github.com/external-secrets/external-secrets/config/crds/bases?ref=v0.9.14
SOPS_SECRETS=kubernetes/proxmox/core/secrets/sealed-secrets/sealed-secrets-keypair.yaml
CREATE_SEALED_SECRET=true
