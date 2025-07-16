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

## Installation

### Quick Start

```bash
# Add the Helm repository (if using a chart repository)
helm repo add devops-bridge https://sysintelligent.github.io/devops-bridge

# Install the chart
helm install devops-bridge ./dist/helm/devops-bridge

# Or install from local chart
helm install devops-bridge ./dist/helm/devops-bridge
```

### Custom Values

Create a custom values file:

```yaml
# my-values.yaml
replicaCount: 3
image:
  repository: my-registry/devops-bridge
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
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `sysintelligent/devops-bridge` |
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

## Building the Container Image

Build the container image using the provided Dockerfile:

```bash
# Build the image
docker build -f dist/helm/devops-bridge/Dockerfile -t sysintelligent/devops-bridge:latest .

# Push to registry
docker push sysintelligent/devops-bridge:latest
```

## Contributing

Please refer to the main project's [Contributing Guide](../../../CONTRIBUTING.md) for details on how to contribute to this Helm chart.

## License

This Helm chart is licensed under the Apache License 2.0 - see the [LICENSE](../../../LICENSE) file for details. 