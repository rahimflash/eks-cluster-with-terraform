# Terraform EKS Cluster with Fargate and Managed Node Groups

This Terraform configuration creates a production-grade Amazon EKS cluster with both Fargate profiles and managed node groups, following AWS best practices.

## Features

- **Multi-AZ EKS Cluster** with configurable Kubernetes version
- **Mixed Compute Strategy**:
  - Managed Node Groups for stateful workloads
  - Fargate profiles for serverless workloads
- **Secure Networking**:
  - VPC with public and private subnets
  - Properly configured security groups
- **IAM Best Practices**:
  - IRSA (IAM Roles for Service Accounts)
  - Least privilege roles for Fargate and node groups
- **Observability**:
  - Control plane logging enabled
  - CloudWatch monitoring for nodes
- **State Management**:
  - S3 backend with versioning and encryption
  - DynamoDB for state locking

## Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│                            AWS Account                                │
│                                                                       │
│  ┌───────────────────┐    ┌───────────────────┐                      │
│  │    EKS Cluster    │    │    VPC Module     │                      │
│  │                   │    │                   │                      │
│  │ ┌───────────────┐ │    │ ┌───────────────┐ │    ┌───────────────┐ │
│  │ │ Control Plane │ │    │ │ Public Subnets │ │    │  S3 Backend   │ │
│  │ └───────────────┘ │    │ └───────────────┘ │    │  (State)      │ │
│  │                   │    │                   │    └───────────────┘ │
│  │ ┌───────────────┐ │    │ ┌───────────────┐ │    ┌───────────────┐ │
│  │ │  Fargate Pods │ │    │ │ Private Subnet│ │    │ DynamoDB Lock │ │
│  │ └───────────────┘ │    │ └───────────────┘ │    │    Table      │ │
│  │                   │    │                   │    └───────────────┘ │
│  │ ┌───────────────┐ │    │ ┌───────────────┐ │                      │
│  │ │ Managed Nodes │ │    │ │   NAT GW      │ │                      │
│  │ └───────────────┘ │    │ └───────────────┘ │                      │
│  └───────────────────┘    └───────────────────┘                      │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. AWS Account with proper IAM permissions
2. Terraform v1.3.0 or later
3. AWS CLI configured
4. kubectl installed
5. helm (for addons)

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the execution plan

```bash
terraform plan
```

### 3. Apply the configuration

```bash
terraform apply
```

### 4. Configure kubectl

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
```

## Configuration

### Input Variables

Edit `variables.tf` to customize:

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | EKS cluster name | `eks-cluster` |
| `cluster_version` | Kubernetes version | `1.32` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `private_subnets` | List of private subnets | `["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]` |
| `public_subnets` | List of public subnets | `["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]` |

| `environment` | Environment tag | `dev` |

### Node Groups

Configured in `node_groups.tf`:

1. **General Purpose Nodes**:
   - Instance type: t3.small
   - Auto-scaling: 1-3 nodes
   - Default Kubernetes labels

2. **GPU Nodes** (optional):
   - Instance type: g4dn.xlarge
   - Scale to 0 when not in use
   - GPU-specific taints

### Fargate Profiles

Configured in `fargate.tf`:

1. **Default Profile**:
   - Runs pods in `default` and `kube-system` (CoreDNS) namespaces

2. **Monitoring Profile**:
   - Dedicated for monitoring workloads

## Security

- **Pod-to-Pod Communication**: Restricted by Kubernetes Network Policies
- **IAM Roles**: Least privilege with IRSA
- **Data Encryption**: EBS volumes encrypted by default
- **API Access**: Restricted to VPC CIDR by default

## Maintenance

### Upgrading Kubernetes Version

1. Update `cluster_version` in `variables.tf`
2. Review upgrade path in AWS documentation
3. Apply changes:

```bash
terraform apply
```

### Adding Node Groups

1. Add a new module block in `node_groups.tf`
2. Define instance types and scaling parameters
3. Apply changes

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API endpoint |
| `node_group_arns` | ARNs of managed node groups |
| `fargate_profile_arns` | ARNs of Fargate profiles |
| `configure_kubectl` | Command to configure kubectl |

## Troubleshooting

### Common Issues

1. **Insufficient IAM Permissions**:
   - Ensure your AWS credentials have proper permissions
   - Check CloudTrail logs for denied actions

2. **VPC Limits**:
   - AWS accounts have default VPC limits
   - Request limit increases if needed

3. **Pod Networking Issues**:
   - Verify CNI plugin is properly installed
   - Check VPC CNI logs:

```bash
kubectl logs -n kube-system -l k8s-app=aws-node
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

Twum Gilbert