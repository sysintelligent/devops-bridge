# DevOps Bridge Helm Chart

A Helm chart for deploying the DevOps Bridge backend server to Kubernetes clusters.

## Overview

DevOps Bridge is a tool between developers and complex backend infrastructure. It provides a modern microservices architecture with Go backend, Next.js frontend, and CLI.

This Helm chart deploys the Go backend server which provides:
- REST API on port 8080
- gRPC API on port 9090
- Kubernetes integration
- Authentication and authorization
- Health monitoring

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- kubectl configured to communicate with your cluster
- Docker (for building and pushing images)
- Docker Hub account (sysintelligent)

## Quick Reference

### Docker Hub Commands
```bash
# Build and push image
./build-and-push.sh

# Deploy to Kubernetes (uses devops-bridge namespace by default)
./deploy.sh -e development

# Build, push, and deploy
./deploy.sh -e development -b -p
```

### Docker Hub Repository
- **URL**: https://hub.docker.com/r/sysintelligent/devops-bridge
- **Image**: `sysintelligent/devops-bridge:latest`

## Installation

### Quick Start

```bash
# Add the Helm repository (if using a chart repository)
helm repo add devops-bridge https://sysintelligent.github.io/devops-bridge

# Install the chart
helm install devops-bridge ./dist/helm/devops-bridge

# Or install from local chart (creates devops-bridge namespace)
helm install devops-bridge ./dist/helm/devops-bridge
```

### Custom Values

Create a custom values file:

```yaml
# my-values.yaml
namespace:
  create: true
  name: "devops-bridge"
  annotations:
    environment: production

replicaCount: 3
image:
  repository: sysintelligent/devops-bridge
  tag: "v1.0.0"

service:
  type: LoadBalancer

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

config:
  logLevel: "debug"
  auth:
    demoUserToken: "my-user-token"
    demoAdminToken: "my-admin-token"
```

Install with custom values:

```bash
helm install devops-bridge ./dist/helm/devops-bridge -f my-values.yaml
```

## Configuration

### Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.create` | Create namespace if it doesn't exist | `true` |
| `namespace.name` | Namespace name | `devops-bridge` |
| `namespace.annotations` | Annotations for the namespace | `{}` |
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `sysintelligent/devops-bridge` (Docker Hub) |
| `image.tag` | Container image tag | `latest` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.httpPort` | HTTP service port | `8080` |
| `service.grpcPort` | gRPC service port | `9090` |
| `ingress.enabled` | Enable ingress | `false` |
| `resources` | CPU/Memory resource requests/limits | `{}` |
| `autoscaling.enabled` | Enable horizontal pod autoscaler | `false` |
| `config.logLevel` | Application log level | `info` |
| `config.auth.demoUserToken` | Demo user authentication token | `demo-token` |
| `config.auth.demoAdminToken` | Demo admin authentication token | `admin-token` |

### Service Types

- **ClusterIP**: Internal cluster access only
- **NodePort**: Access via node IP and port
- **LoadBalancer**: External load balancer (cloud providers)

### Ingress Configuration

Enable ingress for external access:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: devops-bridge.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: devops-bridge-tls
      hosts:
        - devops-bridge.example.com
```

### Namespace Management

The chart automatically creates and manages the `devops-bridge` namespace:

```yaml
namespace:
  create: true
  name: "devops-bridge"
  annotations:
    environment: production
    managed-by: helm
```

You can customize the namespace configuration or disable automatic creation:

```yaml
# Use existing namespace
namespace:
  create: false
  name: "existing-namespace"

# Custom namespace with annotations
namespace:
  create: true
  name: "my-custom-namespace"
  annotations:
    team: devops
    project: bridge
```

### Resource Management

Configure resource limits and requests:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Autoscaling

Enable horizontal pod autoscaling:

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

## Usage

### Accessing the Application

After installation, you can access the application using the commands provided in the Helm notes:

```bash
# Get the application URL
kubectl get svc devops-bridge

# Port forward for local access
kubectl port-forward svc/devops-bridge 8080:8080 9090:9090
```

### API Endpoints

- **Health Check**: `GET /health`
- **REST API**: `GET /api/applications`
- **gRPC API**: Port 9090

### Authentication

Include authentication tokens in requests:

```bash
# REST API with authentication
curl -H "Authorization: Bearer demo-token" \
  http://localhost:8080/api/applications

# gRPC API (requires gRPC client)
grpcurl -H "Authorization: Bearer demo-token" \
  localhost:9090 list
```

## Monitoring

### Prometheus Integration

Enable Prometheus monitoring:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
  prometheus:
    enabled: true
    path: /metrics
```

### Health Checks

The application includes built-in health checks:
- Liveness probe: `/health` endpoint
- Readiness probe: `/health` endpoint

## Security

### RBAC

The chart creates necessary RBAC resources:
- ServiceAccount for pod identity
- ClusterRole with read permissions for Kubernetes resources
- ClusterRoleBinding to bind the role to the service account

### Security Context

Configure security context for enhanced security:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=devops-bridge
kubectl describe pod <pod-name>
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=devops-bridge
kubectl logs -f <pod-name>
```

### Check Service

```bash
kubectl get svc devops-bridge
kubectl describe svc devops-bridge
```

### Common Issues

1. **Image Pull Errors**: Ensure the container image exists and is accessible
2. **RBAC Issues**: Verify the service account has necessary permissions
3. **Port Conflicts**: Check if ports 8080/9090 are already in use
4. **Resource Limits**: Adjust resource requests/limits if pods are being evicted

### Docker Hub Specific Issues

1. **Authentication Errors**:
   ```bash
   # Login to Docker Hub
   docker login
   
   # Check if you're logged in
   docker info | grep Username
   ```

2. **Image Not Found**:
   ```bash
   # Check if image exists on Docker Hub
   docker pull sysintelligent/devops-bridge:latest
   
   # Build and push if missing
   ./build-and-push.sh -l
   ```

3. **Permission Denied**:
   ```bash
   # Ensure you have push access to the repository
   docker push sysintelligent/devops-bridge:latest
   
   # Check repository permissions on Docker Hub
   ```

4. **Network Issues**:
   ```bash
   # Test Docker Hub connectivity
   curl -I https://hub.docker.com
   
   # Check DNS resolution
   nslookup hub.docker.com
   ```

## Upgrading

```bash
# Upgrade with new values
helm upgrade devops-bridge ./dist/helm/devops-bridge -f my-values.yaml

# Upgrade with new chart version
helm upgrade devops-bridge ./dist/helm/devops-bridge --version 0.2.0
```

## Uninstalling

```bash
helm uninstall devops-bridge
```

## Docker Hub Integration

This Helm chart is configured to use the Docker Hub repository: `sysintelligent/devops-bridge`

### Docker Hub Repository
- **Repository**: [sysintelligent/devops-bridge](https://hub.docker.com/r/sysintelligent/devops-bridge)
- **Default Tag**: `latest`
- **Supported Tags**: `latest`, `v1.0.0`, `v1.1.0`, etc.

### Building the Container Image

#### Manual Build

Build the container image using the provided Dockerfile:

```bash
# Build the image
docker build -f dist/helm/devops-bridge/Dockerfile -t sysintelligent/devops-bridge:latest .

# Push to Docker Hub
docker push sysintelligent/devops-bridge:latest
```

#### Using the Build Script (Recommended)

For convenience, use the provided build script:

```bash
# Build and push with latest tag
./build-and-push.sh

# Build and push with specific tag
./build-and-push.sh -t v1.0.0

# Build only (don't push)
./build-and-push.sh -b

# Login to Docker Hub and push
./build-and-push.sh -l

# Show help
./build-and-push.sh -h
```

### Docker Hub Authentication

Before pushing to Docker Hub, you need to authenticate:

```bash
# Login to Docker Hub
docker login

# Or use the build script with login
./build-and-push.sh -l
```

### Image Configuration

The Helm chart is pre-configured to use your Docker Hub repository:

```yaml
image:
  repository: sysintelligent/devops-bridge
  tag: "latest"
  pullPolicy: IfNotPresent
```

### Available Images

The following images are available on Docker Hub:
- `sysintelligent/devops-bridge:latest` - Latest development version
- `sysintelligent/devops-bridge:v1.0.0` - Stable release version
- `sysintelligent/devops-bridge:v1.1.0` - Feature release version

### Pulling Images

To pull the image manually:

```bash
# Pull latest version
docker pull sysintelligent/devops-bridge:latest

# Pull specific version
docker pull sysintelligent/devops-bridge:v1.0.0
```

### Deploying with Docker Hub Images

The Helm chart automatically pulls images from your Docker Hub repository:

```bash
# Deploy with latest image
helm install devops-bridge . -f values-development.yaml

# Deploy with specific image tag
helm install devops-bridge . -f values-production.yaml \
  --set image.tag=v1.0.0

# Deploy with custom image configuration
helm install devops-bridge . -f my-values.yaml \
  --set image.repository=sysintelligent/devops-bridge \
  --set image.tag=v1.0.0
```

### Using the Deployment Script

The deployment script integrates with Docker Hub:

```bash
# Deploy using existing Docker Hub image
./deploy.sh -e development

# Build, push to Docker Hub, and deploy
./deploy.sh -e development -b -p

# Deploy with specific image tag
./deploy.sh -e production -f values-production.yaml
```

## Contributing

Please refer to the main project's [Contributing Guide](../../../CONTRIBUTING.md) for details on how to contribute to this Helm chart.

## License

This Helm chart is licensed under the Apache License 2.0 - see the [LICENSE](../../../LICENSE) file for details. 