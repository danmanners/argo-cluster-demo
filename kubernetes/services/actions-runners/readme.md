# Runner Scale Set and Runners

```shell
# Create the Namespace and CRDs
kubectl apply -k kubernetes/services/actions-runners --server-side

# Install the Runner Scale Set Controller
helm template gha-rs-controller \
    --namespace actions \
    --skip-crds \
    --values kubernetes/services/actions-runners/controller/values.yaml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
    --version 0.9.1

# Install the Runner Scale Set itself
helm template kastiron-runners \
    --namespace actions \
    --values kubernetes/services/actions-runners/runners/values.yaml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --version 0.9.1
```
