#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
######################
# SET APIC VARIABLES #
######################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
echo "Getting info..."
API_GTWY_MGR=$(oc get route remote-api-gw-gateway-manager -n cp4i-dp -o jsonpath='{.spec.host}')
API_GTWY_EP=$(oc get route remote-api-gw-gateway -n cp4i-dp -o jsonpath='{.spec.host}')
#
echo
echo "API Gateway Service info:"
echo "Management Endpoint URL: https://"$API_GTWY_MGR
echo "API Endpoint Base URL: https://"$API_GTWY_EP
echo
