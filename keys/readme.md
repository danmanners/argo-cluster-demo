# Generating Encryption Keys

In order to encrypt and decrypt secrets, you will need to generate two keypairs. One X509 Certificate Pair for [Sealed Secrets](https://external-secrets.io/v0.9.11/) and one [Age Key](https://github.com/FiloSottile/age) to encrypt your Sealed Secret private key. This will allow you to store and deploy/re-deploy your Sealed Secret private key without having to worry about it being compromised.

> [!IMPORTANT]
> You should **NEVER** commit your Sealed Secret private key to source control unencrypted, nor should you ever commit your Age private key to source control unencrypted. If you do, you may end up exposing secrets to the public. [Read this quick blog post from GitGuardian](https://blog.gitguardian.com/what-t`o-do-if-you-expose-a-secret/) on what to do, but the TL;DR is **Breathe**, **Rotate**, **Revoke**.

## Sealed Secrets Keypair

You can generate your own keys in this directory by running the following commands.

```bash
# Set the following variables to your desired values
export PRIVATEKEY="sealed-secret.key"
export PUBLICKEY="sealed-secret.crt"

openssl req -x509 \
-days 365 -nodes \
-newkey rsa:4096 \
-keyout "$PRIVATEKEY" \
-out "$PUBLICKEY" \
-subj "/CN=sealed-secret/O=sealed-secret"
```

## Age / SOPS Keypair

Using the `age` tool, we can generate the SOPS key we will use to encrypt our Sealed Secret private key.

```bash
# Generate your age keypair
age-keygen -o age.key
# Get the Public Key for your age keypair
AGEPUBKEY=$(age-keygen -y age.key)
# Encrypt the Sealed Secret private key
sops -e -i -a=${AGEPUBKEY} sealed-secret.key
```

## Creating your `.sops.yaml` file

Finally, we can create our `.sops.yaml` file that will be used by SOPS to encrypt and decrypt our secrets. This file will be used by SOPS to encrypt (and decrypt) our secrets.

```bash
# Create your .sops.yaml file
sed 's/REPLACE_THIS/'${AGEPUBKEY}'/g' sops_template.yaml > ../.sops.yaml
```
