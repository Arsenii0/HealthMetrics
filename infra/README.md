# HealthMetrics Infrastructure

AWS EKS infrastructure setup using Terraform.

## Prerequisites

- AWS CLI configured: `aws configure`
- Terraform >= 1.0
- kubectl

## Quick Deploy

```bash
# 1. Deploy
terraform init
terraform plan
terraform apply

# 2. Connect kubectl
aws eks --region us-west-2 update-kubeconfig --name healthmetrics-cluster
kubectl get nodes
```

## What Gets Created

- **EKS Cluster** - Kubernetes control plane
- **VPC & Networking** - Private/public subnets, NAT gateway
- **Node Group** - Auto-scaling worker nodes (SPOT instances)
- **SQS Queue** - Message processing queue
- **IAM Roles** - Security permissions for pods

## Configuration

Key variables in `terraform.tfvars`:
- `cluster_name` - EKS cluster name
- `node_instance_types` - Worker node sizes (default: t3.small)
- `node_capacity_type` - SPOT (cheap) or ON_DEMAND
- `enable_irsa` - Enable IAM roles for service accounts (required for production)

## Cleanup

```bash
terraform destroy
```