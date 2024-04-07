# Node Feature Discovery

[Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery) is a Kubernetes add-on for detecting hardware features of a node and advertising them to the system. It is a DaemonSet that runs on each node in the cluster and queries hardware and software attributes of the node.

```bash
# Add the CoreDNS Helm repository
helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts

# Update your local Helm chart repository cache
helm repo update

# Template out and install the Node Feature Discovery chart via pipe to `kubectl apply`
helm template node-feature-discovery node-feature-discovery/node-feature-discovery \
-n kube-system --version 0.15.4 --values values.yaml | \
kubectl apply -f -
```
