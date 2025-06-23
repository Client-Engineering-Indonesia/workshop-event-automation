#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
######################
# SET APIC VARIABLES #
######################
ACE_INST_NAME='jgr-ace-bake-cp4i'
ACE_NAMESPACE='tools'
API_PATH='/jgraceivt/v1/hello'
#TARGET_URL=$(oc get IntegrationRuntime $ACE_INST_NAME -n $ACE_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="http endpoint")]}{.uri}{end}')$API_PATH
TARGET_URL=$(oc get IntegrationRuntime $ACE_INST_NAME -n $ACE_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="http endpoint")].uri}')$API_PATH
echo "Invoking Integration Runtime endpoint:"
echo
curl $TARGET_URL; echo
echo