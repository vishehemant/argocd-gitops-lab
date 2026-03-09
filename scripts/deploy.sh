#!/bin/bash

# Set the namespace for the deployment
NAMESPACE="default"

# Apply the Kubernetes manifests for the Node.js application
echo "Deploying Node.js application..."
kubectl apply -f ../apps/nginx/deployment.yaml -n $NAMESPACE
kubectl apply -f ../apps/nginx/service.yaml -n $NAMESPACE
kubectl apply -f ../apps/nginx/rollout.yaml -n $NAMESPACE

# Apply the Kubernetes manifests for the Prometheus application
echo "Deploying Prometheus application..."
kubectl apply -f ../apps/prometheus/deployment.yaml -n $NAMESPACE
kubectl apply -f ../apps/prometheus/service.yaml -n $NAMESPACE
kubectl apply -f ../apps/prometheus/configmap.yaml -n $NAMESPACE

# Wait for the deployments to be ready
echo "Waiting for Node.js deployment to be ready..."
kubectl rollout status deployment/nodejs-demo -n $NAMESPACE

echo "Waiting for Prometheus deployment to be ready..."
kubectl rollout status deployment/prometheus -n $NAMESPACE

echo "Deployment completed successfully."