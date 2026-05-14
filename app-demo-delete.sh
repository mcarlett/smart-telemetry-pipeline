#!/bin/bash
set -e

echo "=== Removing OpenTelemetry Demo Application ==="

NS=$(oc project -q)
echo "Namespace: ${NS}"

echo ""
echo "--- Uninstalling Helm release ---"
helm uninstall otel-demo -n "${NS}" 2>/dev/null || true

echo ""
echo "--- Deleting frontend route ---"
oc delete route otel-demo-frontend --ignore-not-found 2>/dev/null || true

echo ""
echo "--- Waiting for pods to terminate ---"
oc wait pod -l opentelemetry.io/name --for=delete --timeout=120s 2>/dev/null || true

echo ""
echo "=== Cleanup complete ==="
oc get pods 2>/dev/null || true
