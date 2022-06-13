#!/bin/bash

set -aueo pipefail

if [ ! -f .env ]; then
    echo -e "\nThere is no .env file in the root of this repository."
    echo -e "Copy the values from .env.example into .env."
    echo -e "Modify the values in .env to match your setup.\n"
    echo -e "    cat .env.example > .env\n\n"
    exit 1
fi

# shellcheck disable=SC1091
source .env

# Set meaningful defaults for env vars we expect from .env
MESH_NAME="${MESH_NAME:-osm}"
K8S_NAMESPACE="${K8S_NAMESPACE:-osm-system}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
ECHO_CONSUMER_NAMESPACE="${ECHO_CONSUMER_NAMESPACE:-echo-consumer}"
ECHO_DUBBO_SERVER_NAMESPACE="${ECHO_DUBBO_SERVER_NAMESPACE:-echo-dubbo-server}"
ECHO_GRPC_SERVER_NAMESPACE="${ECHO_GRPC_SERVER_NAMESPACE:-echo-grpc-server}"
ECHO_HTTP_SERVER_NAMESPACE="${ECHO_HTTP_SERVER_NAMESPACE:-echo-http-server}"
CERT_MANAGER="${CERT_MANAGER:-tresor}"
CTR_REGISTRY="${CTR_REGISTRY:-localhost:5000}"
CTR_REGISTRY_CREDS_NAME="${CTR_REGISTRY_CREDS_NAME:-acr-creds}"
DEPLOY_TRAFFIC_SPLIT="${DEPLOY_TRAFFIC_SPLIT:-true}"
CTR_TAG="${CTR_TAG:-$(git rev-parse HEAD)}"
IMAGE_PULL_POLICY="${IMAGE_PULL_POLICY:-Always}"
ENABLE_DEBUG_SERVER="${ENABLE_DEBUG_SERVER:-true}"
ENABLE_EGRESS="${ENABLE_EGRESS:-false}"
ENABLE_RECONCILER="${ENABLE_RECONCILER:-false}"
DEPLOY_GRAFANA="${DEPLOY_GRAFANA:-false}"
DEPLOY_JAEGER="${DEPLOY_JAEGER:-false}"
TRACING_ADDRESS="${TRACING_ADDRESS:-jaeger.${K8S_NAMESPACE}.svc.cluster.local}"
ENABLE_FLUENTBIT="${ENABLE_FLUENTBIT:-false}"
DEPLOY_PROMETHEUS="${DEPLOY_PROMETHEUS:-false}"
SIDECAR_LOG_LEVEL="${SIDECAR_LOG_LEVEL:-debug}"
USE_PRIVATE_REGISTRY="${USE_PRIVATE_REGISTRY:-true}"
PUBLISH_IMAGES="${PUBLISH_IMAGES:-false}"
TIMEOUT="${TIMEOUT:-300s}"

# For any additional installation arguments. Used heavily in CI.
optionalInstallArgs=$*

exit_error() {
    error="$1"
    echo "$error"
    exit 1
}

# Check if Docker daemon is running
# docker info > /dev/null || { echo "Docker daemon is not running"; exit 1; }

TIMEOUT="${TIMEOUT:-300s}"

# cleanup stale resources from previous runs
./demo/clean-kubernetes.sh

osm install \
    --mesh-name "$MESH_NAME" \
    --osm-namespace "$K8S_NAMESPACE" \
    --verbose \
    --set=osm.enablePermissiveTrafficPolicy=true \
    --set=osm.deployPrometheus="$DEPLOY_PROMETHEUS" \
    --set=osm.deployGrafana="$DEPLOY_GRAFANA" \
    --set=osm.deployJaeger="$DEPLOY_JAEGER" \
    --set=osm.controllerLogLevel="trace" \
    --timeout="$TIMEOUT"

./demo/configure-app-namespaces.sh
# update envoy sidecare resources
./scripts/update-envoy-resources.sh

./demo/deploy-apps.sh    

./demo/expose-prometheus-grafana.sh