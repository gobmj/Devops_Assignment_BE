#!/bin/bash

# Variables
K8S_NAMESPACE=$1
ISTIO_HOST=$2
ISTIO_PRIMARY_SUBSET=$3
ISTIO_CANARY_SUBSET=$4
CANARY_TRAFFIC_PERCENTAGE=$5

# Calculate traffic split
PRIMARY_TRAFFIC=$((100 - CANARY_TRAFFIC_PERCENTAGE))

# Create VirtualService YAML file
cat > /tmp/virtual-service.yaml <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: todo-app
  namespace: ${K8S_NAMESPACE}
spec:
  hosts:
    - ${ISTIO_HOST}
  http:
    - route:
        - destination:
            host: ${ISTIO_HOST}
            subset: ${ISTIO_PRIMARY_SUBSET}
          weight: ${PRIMARY_TRAFFIC}
        - destination:
            host: ${ISTIO_HOST}
            subset: ${ISTIO_CANARY_SUBSET}
          weight: ${CANARY_TRAFFIC_PERCENTAGE}
EOF

# Apply the configuration
kubectl apply -f /tmp/virtual-service.yaml
