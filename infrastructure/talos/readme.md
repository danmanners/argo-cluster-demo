# Talos Configs using Talhelper

In order to generate the configs for your cluster, you will need to run the following commands:

```bash
# Generate your Initial Talos Cluster Secrets
for deployDir in cloud proxmox; do
    if [[ ! infrastructure/talos/${deployDir}/talsecret.sops.yaml ]]; then
        talhelper gensecret > infrastructure/talos/${deployDir}/talsecret.sops.yaml
        # Encrypt your secrets using the AGE key with SOPS
        sops -e -i infrastructure/talos/${deployDir}/talsecret.sops.yaml
    else
        echo "talsecret.sops.yaml already exists in the '${deployDir}' directory. Skipping..."
    fi
done
```

Once you have generated your secrets, you can validate that your cluster config files will work by running:

```bash
# Set your domain
DOMAIN="danmanners.com"

# Generate your Talos Cluster Configs
for deployDir in cloud proxmox; do
    # Replace the DOMAIN variable with your domain
    cd infrastructure/talos/${deployDir}
    if [ ${deployDir} = "proxmox" ]; then
        sed -i '.bak' 's|DOMAIN|homelab.'${DOMAIN}'|g' talconfig.yaml
    else
        sed -i '.bak' 's|DOMAIN|'${deployDir}'.'${DOMAIN}'|g' talconfig.yaml
    fi
    talhelper genconfig
    cd -
done
```
