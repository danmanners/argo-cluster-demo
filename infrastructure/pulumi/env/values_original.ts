import { Node } from "../types/types";

// General Values
export const general = {
  domain: "your_domain_here.com", // Replace this with your own public domain
  github_username: "YourUsernameHere", // Replace this with your own GitHub Username
  public_hosted_zone: "Z016942938TFLEH1J2FS1", // Replace this with your own Route53 Hosted Zone ID
  bucket_name: "cloud-homelab-oidc-auth", // Replace this with your own S3 Bucket Name
  domain_comment: "Internal DNS HostedZone for the cloud cluster",
};

// Global Tags
export const tags = {
  environment: "homelab",
  project_name: "cloud-homelab",
  repo_name: "homelab-kube-cluster",
  github_url: `https://github.com/${general.github_username}/homelab-kube-cluster`,
};

// Cloud Setup Values
export const cloud_auth = {
  aws_region: "us-east-1",
  aws_profile: "default",
  aws_account_id: "001122334455", // Replace this with your own AWS Account ID
};

export const user_data = {
  bastion: `
#cloud-config
users:
  - name: ${general.github_username}
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    ssh_import_id:
      - gh:${general.github_username}
`,
};

export const dns = {
  kubeControlPlane: {
    kubernetes_endpoint: `talos.${general.domain}`,
    ttl: 300,
    type: "A",
    values: ["172.29.8.5"],
  },
};

// VPC Setup and Networking
export const network = {
  // VPC Cidr Block Definition
  vpc: {
    name: "homelab-vpc",
    cidr_block: "172.29.0.0/19",
  },
  // Network Load Balancer Definition
  nlb: {
    name: "talos-nlb",
  },
  // Subnet Definitions
  subnets: {
    public: [
      {
        name: "public1a",
        cidr_block: "172.29.0.0/23",
        az: "a",
      },
      {
        name: "public1b",
        cidr_block: "172.29.2.0/23",
        az: "b",
      },
    ],
    private: [
      {
        name: "private1a",
        cidr_block: "172.29.8.0/21",
        az: "a",
      },
      {
        name: "private1b",
        cidr_block: "172.29.16.0/21",
        az: "b",
      },
    ],
  },
};

// Compute Values
export const compute: {
  kube_nodes: Node[];
  bastion: Node[];
} = {
  // List of all nodes in the cluster
  kube_nodes: [
    {
      name: "kube-control-1",
      instance_size: "t3.medium",
      arch: "amd64",
      subnet_name: "private1a",
      root_volume_size: 40,
      root_volume_type: "gp3",
      privateIp: "172.29.8.5",
    },
    {
      name: "kube-worker-1",
      instance_size: "t3.medium",
      arch: "amd64",
      subnet_name: "private1a",
      root_volume_size: 40,
      root_volume_type: "gp3",
      privateIp: "172.29.8.100",
    },
    {
      name: "kube-worker-2",
      instance_size: "t3.medium",
      arch: "amd64",
      subnet_name: "private1b",
      root_volume_size: 40,
      root_volume_type: "gp3",
      privateIp: "172.29.16.100",
    },
  ],
  // Configuration data for the bastion node
  bastion: [
    {
      name: "bastion",
      instance_size: "t3.micro",
      arch: "amd64",
      subnet_name: "public1a",
      root_volume_size: 40,
      root_volume_type: "gp3",
      privateIp: "172.29.0.101",
    },
  ],
};

// AMIs
export const amis: {
  [region: string]: {
    masters_amd64: string;
    masters_arm64: string;
    workers_amd64?: string; // Optional; only if you're using x64 instances
    workers_arm64?: string; // Optional; only if you're using t4g instances
    bastion_amd64?: string; // Optional; only if you're using x64 instances
    bastion_arm64?: string; // Optional; only if you're using x64 instances
  };
} = {
  // US-East-1 Regional AMIs
  "us-east-1": {
    // Bastion
    // https://cloud-images.ubuntu.com/locator/ec2/, search '22.04 us-east-1'
    bastion_amd64: "ami-0a5f04cdf7758e9f0", // Ubuntu Linux 22.04
    // amd64 / 64-Bit x64 Architecture
    masters_amd64: "ami-0fd267b9f1b72a285", // v1.6.0
    workers_amd64: "ami-0fd267b9f1b72a285", // v1.6.0
    // arm64 / 64-Bit ARM Architecture
    masters_arm64: "ami-0874ca2dcfec825b4", // v1.6.0
    workers_arm64: "ami-0874ca2dcfec825b4", // v1.6.0
  },
};

// Security Groups
export const security_groups = {
  // Security Group for the Talos Access within the VPC
  talos_configuration: {
    name: "talos_configuration",
    description:
      "Security Group for Talos Configuration, Management, and Communication",
    ingress: [
      // Allow all inbound traffic from the VPC
      // In the future, we want to lock this down to only the
      // required ports and protocols for Talos and Kubernetes
      // cross-node communication
      {
        description: "Self - Everything TCP",
        port: -1,
        protocol: "all",
        cidr_blocks: [network.vpc.cidr_block],
      },
    ],
    egress: [
      {
        description: "Talos - Egress",
        port: -1,
        protocol: "all",
        cidr_blocks: [network.vpc.cidr_block],
      },
    ],
  },
  // Security Group for K8s Resources
  kube_ingress: {
    name: "kube_ingress",
    description: "Security Group for Kubernetes Resource Ingress",
    ingress: [
      {
        description: "K8s - Kubernetes API Server",
        port: 6443,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "K8s - Kubernetes/Cilium Logging",
        port: 10250,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "K8s - NodePort Services",
        port_start: 30000,
        port_end: 32767,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "Self - Everything TCP",
        port: -1,
        protocol: "all",
        // Loop through the privateIp of each node and add them to the cidr_blocks
        cidr_blocks: compute.kube_nodes.map((n) => `${n.privateIp}/32`),
      },
    ],
    egress: [
      {
        description: "Full Egress",
        port: -1,
        protocol: "all",
        cidr_blocks: ["0.0.0.0/0"],
      },
    ],
  },
  // External Ingress to the Network Load Balancer
  nlb_ingress: {
    name: "nlb_inbound_traffic",
    description: "Permitted inbound traffic",
    ingress: [
      {
        description: "ICMP Inbound",
        port: -1,
        protocol: "icmp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "SSH Inbound",
        port: 22,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "HTTP Inbound",
        port: 80,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "HTTPS Inbound",
        port: 443,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
    ],
    egress: [
      // Allow all outbound traffic
      {
        description: "Internet",
        port: -1,
        protocol: "all",
        cidr_blocks: ["0.0.0.0/0"],
      },
    ],
  },
  bastion: {
    name: "bastion",
    description: "Permitted inbound traffic to the Bastion Host",
    ingress: [
      {
        description: "ICMP Inbound",
        port: -1,
        protocol: "icmp",
        cidr_blocks: ["0.0.0.0/0"],
      },
      {
        description: "SSH Inbound",
        port: 22,
        protocol: "tcp",
        cidr_blocks: ["0.0.0.0/0"],
      },
    ],
    egress: [
      {
        description: "Internet",
        port: -1,
        protocol: "all",
        cidr_blocks: ["0.0.0.0/0"],
      },
    ],
  },
};
