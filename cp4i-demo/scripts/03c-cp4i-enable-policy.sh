#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
read -p "Press <Enter> to execute script..."
if [ "$(oc get clusterversion --no-headers | awk '{print $2}' | cut -d'.' -f2)" -lt "17" ]
then
  echo "This CP4I feature requires OCP v4.17 or higher"
  exit 1
else
SERVICE_ACCOUNT_NAME=$(oc get platformnavigators -A -o go-template='{{if eq (len .items) 1}}{{range .items}}{{printf "%s-ibm-integration-platform-navigator" .metadata.name}}{{end}}{{end}}')
NAMESPACE=$(oc get platformnavigators -A -o go-template='{{if eq (len .items) 1}}{{range .items}}{{printf "%s" .metadata.namespace}}{{end}}{{end}}' )
if [ -z "$SERVICE_ACCOUNT_NAME" ]
then
  echo "\"oc get platformnavigators -A\" did not return 1 PlatformNavigator. ClusterRole/ClusterRoleBinding was not created."
else
  echo "
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cp4i-policy
rules:
  - verbs:
      - create
      - update
      - delete
      - patch
    apiGroups:
      - admissionregistration.k8s.io
    resources:
      - validatingadmissionpolicies
      - validatingadmissionpolicybindings
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cp4i-policy
subjects:
  - kind: ServiceAccount
    name: ${SERVICE_ACCOUNT_NAME}
    namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cp4i-policy" | oc apply -f-
fi
fi