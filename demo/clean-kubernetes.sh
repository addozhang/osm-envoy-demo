#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

TIMEOUT="${TIMEOUT:-90s}"

helm uninstall fsm --namespace "$INGRESS_PIPY_NAMESPACE" || true

osm uninstall mesh -f --mesh-name "$MESH_NAME" --osm-namespace "$K8S_NAMESPACE" --delete-namespace -a

for ns in "$ECHO_CONSUMER_NAMESPACE" "$ECHO_DUBBO_SERVER_NAMESPACE" "$ECHO_GRPC_SERVER_NAMESPACE" "$ECHO_HTTP_SERVER_NAMESPACE"; do
    kubectl delete namespace "$ns" --ignore-not-found --wait --timeout="$TIMEOUT" &
done

wait
