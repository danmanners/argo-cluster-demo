# QEMU Guest Agent

[QEMU Guest Agent](https://wiki.qemu.org/Features/GuestAgent) is a daemon that runs on the virtual machine. It is used to exchange information between the host and guest, and to execute command in the guest. It is used to get the IP address of the guest, to execute commands in the guest, to get the guest time, to get the guest hostname, etc.

```bash
# Add the bjw-s App Template repository
helm repo add bjw-s https://bjw-s.github.io/helm-charts

# Update your local Helm chart repository cache
helm repo update

# Template out and install the QEMU Guest Agent chart via pipe to `kubectl apply`
helm template qemu-guest-agent bjw-s/app-template \
-n kube-system --version 3.1.0 --values values.yaml | \
kubectl apply -f -
```
