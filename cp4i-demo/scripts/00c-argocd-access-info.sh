#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
ARGOCD_URL=$(oc get argocd -n openshift-gitops openshift-gitops -o jsonpath='{.status.host}')
ARGOCD_ADMIN_PWD=$(oc get secret -n openshift-gitops openshift-gitops-cluster -o jsonpath='{.data.admin\.password}' | base64 -d)
echo "ArgoCD UI URL: https://"$ARGOCD_URL
echo "ArgoCD Admin user: admin"
echo "ArgoCD Admin password:" $ARGOCD_ADMIN_PWD