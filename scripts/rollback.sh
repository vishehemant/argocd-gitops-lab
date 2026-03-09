#!/bin/bash

# Rollback script for ArgoCD deployments

# Set the namespace and application name
NAMESPACE="default"
APP_NAME="nodejs-demo"

# Get the current rollout status
CURRENT_ROLLOUT=$(kubectl get rollout $APP_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')

if [ "$CURRENT_ROLLOUT" != "Healthy" ]; then
  echo "Current rollout status is not healthy. Initiating rollback..."

  # Rollback to the previous revision
  kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE

  if [ $? -eq 0 ]; then
    echo "Rollback successful. Current rollout status:"
    kubectl get rollout $APP_NAME -n $NAMESPACE
  else
    echo "Rollback failed."
  fi
else
  echo "Rollout is healthy. No rollback needed."
fi