#!/bin/bash

# shellcheck disable=SC1091
source .env

K8S_NAMESPACE="${K8S_NAMESPACE:-osm-system}"

kubectl patch meshconfig osm-mesh-config -n "$K8S_NAMESPACE" \
  -p '{"spec":{"sidecar":{"resources":{"limits":{"cpu":"1","memory":"512Mi"},"requests":{"cpu":"100m","memory":"64Mi"}}}}}' \
  --type=merge