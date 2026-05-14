#!/bin/bash
set -e

echo "=== Installing OpenTelemetry Demo Application ==="

NS=$(oc project -q)
echo "Namespace: ${NS}"

# Verify OTel Collector is deployed
echo ""
echo "--- Verifying OTel Collector ---"
COLLECTOR_SVC=$(oc get svc -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "${COLLECTOR_SVC}" ]; then
  echo "ERROR: OpenTelemetry Collector service not found. Deploy the pipeline first with ./create.sh"
  exit 1
fi
echo "Using collector: ${COLLECTOR_SVC}"

# Install the OpenTelemetry Demo Helm chart
echo ""
echo "--- Installing OpenTelemetry Demo ---"
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo update

helm install otel-demo open-telemetry/opentelemetry-demo \
  -f deploy/resources/otel-demo-values.yaml \
  --set "default.envOverrides[0].name=OTEL_COLLECTOR_NAME" \
  --set "default.envOverrides[0].value=${COLLECTOR_SVC}" \
  -n "${NS}" --wait --timeout 600s

echo "OpenTelemetry Demo installed"

# Expose the frontend
echo ""
echo "--- Exposing frontend ---"
oc create route edge otel-demo-frontend \
  --service=frontend \
  --port=8080 \
  --dry-run=client -o yaml | oc apply -f -
echo "Frontend route created"

echo ""
echo "=== Installation complete ==="
oc get pods -l opentelemetry.io/name
echo ""
ROUTE=$(oc get route otel-demo-frontend -o jsonpath='https://{.spec.host}' 2>/dev/null)
if [ -n "${ROUTE}" ]; then
  echo "Demo Frontend: ${ROUTE}"
fi
