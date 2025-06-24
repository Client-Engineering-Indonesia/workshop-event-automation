#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo "yq could not be found"; exit 1; fi;
echo "Creating DP Gateway Routes..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
DP_NAMESPACE='cp4i-dp'
###########################################
# CREATE ROUTES FOR STANDALONE DP GATEWAY #
###########################################
STACK_HOST=$(oc get route "${APIC_INST_NAME}-gw-gateway" -n ${APIC_NAMESPACE} -o jsonpath="{.spec.host}" | cut -d'.' -f2-)
echo "Preparing Route File for DP WebUI..."
( echo "cat <<EOF" ; cat templates/template-dp-gw-webui-route.yaml ;) | \
    STACK_HOST=${STACK_HOST} \
    sh > dp-webui-route.yaml
echo "Creating DP WebUI Route..."
oc apply -f dp-webui-route.yaml -n ${DP_NAMESPACE}
echo "Preparing Route File for DP HTTP User Traffic..."
( echo "cat <<EOF" ; cat templates/template-dp-gw-http-route.yaml ;) | \
    STACK_HOST=${STACK_HOST} \
    sh > dp-http-route.yaml
echo "Creating DP HTTP Route..."
oc apply -f dp-http-route.yaml -n ${DP_NAMESPACE}
echo "Cleaning up temp files..."
rm -f dp-webui-route.yaml
rm -f dp-http-route.yaml
echo "DP Routes have been created."
