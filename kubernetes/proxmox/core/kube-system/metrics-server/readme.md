# Kubernetes Metrics Server

[Metrics Server](https://github.com/kubernetes-sigs/metrics-server) is a scalable, efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.

```bash
# Add the Metrics Server Helm repository
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/

# Update your local Helm chart repository cache
helm repo update

# Template out and install the Metrics Server Helm chart via pipe to `kubectl apply`
helm template metrics-server metrics-server/metrics-server \
-n kube-system --version 3.12.1 --values values.yaml | \
kubectl apply -f -
```
