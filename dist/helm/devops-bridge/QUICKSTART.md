# DevOps Bridge Helm Chart - Quick Start Guide

This guide will help you quickly deploy the DevOps Bridge backend server to your Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.0+
- kubectl configured
- Docker (optional, for building custom images)

## Quick Deployment

### 1. Clone and Navigate

```bash
git clone https://github.com/sysintelligent/devops-bridge.git
cd devops-bridge/dist/helm/devops-bridge
```

### 2. Deploy to Development

```bash
# Using the deployment script (recommended)
./deploy.sh -e development

# Or using Helm directly
helm install devops-bridge . -f values-development.yaml
```

### 3. Access the Application

```bash
# Port forward to access locally
kubectl port-forward svc/devops-bridge 8080:8080 9090:9090

# In another terminal, test the health endpoint
curl http://localhost:8080/health
```

## Production Deployment

### 1. Update Configuration

Edit `values-production.yaml` with your production settings:

```yaml
image:
  repository: your-registry/devops-bridge
  tag: "v1.0.0"

ingress:
  enabled: true
  hosts:
    - host: your-domain.com
      paths:
        - path: /
          pathType: Prefix
```

### 2. Deploy to Production

```bash
# Using the deployment script
./deploy.sh -e production

# Or using Helm directly
helm install devops-bridge . -f values-production.yaml --namespace production
```

## Custom Deployment

### 1. Create Custom Values

```yaml
# my-values.yaml
replicaCount: 3
image:
  repository: my-registry/devops-bridge
  tag: "latest"

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### 2. Deploy with Custom Values

```bash
./deploy.sh -f my-values.yaml -n my-namespace
```

## Building Custom Image

### 1. Build and Deploy

```bash
# Build image and deploy
./deploy.sh -e development -b

# Build, push, and deploy
./deploy.sh -e development -b -p
```

### 2. Update Image Registry

Edit the values file to use your registry:

```yaml
image:
  repository: your-registry/devops-bridge
  tag: "latest"
```

## Verification

### 1. Check Deployment Status

```bash
# Check pods
kubectl get pods -l app.kubernetes.io/name=devops-bridge

# Check services
kubectl get svc -l app.kubernetes.io/name=devops-bridge

# Check logs
kubectl logs -l app.kubernetes.io/name=devops-bridge
```

### 2. Test API Endpoints

```bash
# Health check
curl http://localhost:8080/health

# REST API (with authentication)
curl -H "Authorization: Bearer demo-token" \
  http://localhost:8080/api/applications

# gRPC API (requires grpcurl)
grpcurl -H "Authorization: Bearer demo-token" \
  localhost:9090 list
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check if image exists
   docker pull sysintelligent/devops-bridge:latest
   
   # Or build locally
   ./deploy.sh -e development -b
   ```

2. **RBAC Issues**
   ```bash
   # Check service account
   kubectl get serviceaccount -l app.kubernetes.io/name=devops-bridge
   
   # Check cluster role binding
   kubectl get clusterrolebinding -l app.kubernetes.io/name=devops-bridge
   ```

3. **Port Conflicts**
   ```bash
   # Check if ports are in use
   kubectl get svc -A | grep 8080
   kubectl get svc -A | grep 9090
   ```

### Getting Help

```bash
# Show deployment script help
./deploy.sh --help

# Dry run to see what would be deployed
./deploy.sh -e production -d

# Check Helm chart values
helm template devops-bridge . -f values-production.yaml
```

## Next Steps

- [Read the full documentation](README.md)
- [Configure monitoring](README.md#monitoring)
- [Set up ingress for external access](README.md#ingress-configuration)
- [Configure autoscaling](README.md#autoscaling)

## Support

For issues and questions:
- [GitHub Issues](https://github.com/sysintelligent/devops-bridge/issues)
- [Documentation](README.md)
- [Contributing Guide](../../../CONTRIBUTING.md) 