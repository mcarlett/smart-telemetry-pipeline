# OpenTelemetry Demo Application

The [OpenTelemetry Demo](https://opentelemetry.io/docs/platforms/kubernetes/helm/demo/) is a microservice-based e-commerce application instrumented with OpenTelemetry. It generates realistic distributed traces, metrics, and logs across multiple services and programming languages, making it an ideal workload for testing observability pipelines.

## Demo Services

The application simulates an online astronomy shop. The following services are deployed on the Developer Sandbox (a subset of the full demo, optimized for resource quotas):

| Service | Language | Description |
|---------|----------|-------------|
| **Frontend** | TypeScript | Web UI for browsing and purchasing products |
| **Cart** | .NET | Manages user shopping carts backed by Valkey |
| **Checkout** | Go | Orchestrates the checkout flow (payment, shipping) |
| **Payment** | JavaScript | Processes credit card transactions |
| **Currency** | C++ | Converts between currencies |
| **Shipping** | Rust | Calculates shipping costs and tracking |
| **Recommendation** | Python | Suggests related products |
| **Load Generator** | Python/Locust | Simulates continuous user traffic |
| **Flagd** | Go | Feature flag service to inject faults and control behavior |
| **Valkey** | — | In-memory cache for the Cart service |

The following services from the full demo are disabled to fit Developer Sandbox resource quotas and OpenShift SCC constraints: Accounting, Ad, Email, Fraud Detection, Quote, Product Catalog, Product Reviews, Image Provider, Frontend Proxy, LLM, PostgreSQL, and the bundled Kafka (the pipeline's existing Kafka is used instead).

## Prerequisites

- Logged in to the OpenShift cluster (`oc login`)
- Smart Telemetry Pipeline deployed (`./create.sh`) — the demo sends telemetry to the existing OpenTelemetry Collector

## Quick Start

```bash
./app-demo.sh
```

The script:
1. Verifies the OpenTelemetry Collector is running
2. Installs the demo Helm chart with all observability backends disabled (Jaeger, Prometheus, Grafana, OpenSearch)
3. Configures the demo services to export telemetry to the existing collector
4. Creates an OpenShift route for the frontend

Once deployed, the load generator starts automatically, producing a steady stream of traces and logs.

## Accessing the Demo

After installation, the script prints the frontend URL:

```
Demo Frontend: https://otel-demo-frontend-<namespace>.apps.<cluster>/
```

## Customization

### Enabling additional services

The values file at `deploy/resources/otel-demo-values.yaml` controls which services are deployed. To enable a disabled service:

```bash
helm upgrade otel-demo open-telemetry/opentelemetry-demo \
  -f deploy/resources/otel-demo-values.yaml \
  --set components.ad.enabled=true
```

Note that some services (Frontend Proxy, Product Catalog) are disabled due to OpenShift SCC constraints — they require specific UIDs that conflict with the sandbox's security policy.

### Adjusting resources

Override memory/CPU limits per component:

```bash
helm upgrade otel-demo open-telemetry/opentelemetry-demo \
  --reuse-values \
  --set components.frontend.resources.limits.memory=256Mi
```

### Injecting faults via feature flags

The Flagd service controls feature flags that inject errors and latency into the demo services. These generate ERROR-level telemetry that triggers analysis in the pipeline.

## Cleanup

```bash
./app-demo-delete.sh
```

This uninstalls the Helm release, removes the frontend route, and waits for all demo pods to terminate. The Smart Telemetry Pipeline is not affected.

## Troubleshooting

**Pods stuck in Pending**: The Developer Sandbox has resource quotas. Check current usage with `oc describe quota` and disable non-essential services to free resources.

**No telemetry appearing in the pipeline**: Verify the collector endpoint is correctly set:
```bash
oc set env deployment/checkout --list | grep OTEL_COLLECTOR_NAME
```

**Helm install timeout**: Check which pods failed to start:
```bash
oc get pods -l opentelemetry.io/name --field-selector=status.phase!=Running
```

**Frontend route not accessible**: Verify the route and service exist:
```bash
oc get route otel-demo-frontend
oc get svc frontend
```

**SCC errors (FailedCreate)**: Some demo containers specify fixed UIDs incompatible with OpenShift. The values file already handles this for enabled services by clearing `securityContext`. If re-enabling a service causes SCC failures, add a `securityContext` override in the values file:
```yaml
components:
  <service-name>:
    securityContext:
      runAsUser: null
      runAsGroup: null
      runAsNonRoot: null
```
