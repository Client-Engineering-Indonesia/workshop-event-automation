#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the jq utility being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_AVAILABILITY_ZONE='availability-zone-default'
EEM_MANAGER_INST_NAME='eem-demo-mgr'
EEM_GATEWAY_INST_NAME='eem-demo-gw'
EEM_NAMESPACE='tools'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
#################
# LOGIN TO APIC #
#################
echo "Login to APIC with CMC Admin User..."
apic client-creds:clear
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
### Register the event gateway
EEM_MANAGER_APIC_HOST=$(oc get route $EEM_MANAGER_INST_NAME-ibm-eem-apic -n $EEM_NAMESPACE --template='{{ .spec.host }}')
EEM_GATEWAY_RT_HOST=$(oc get route $EEM_GATEWAY_INST_NAME-ibm-egw-rt -n $EEM_NAMESPACE --template='{{ .spec.host }}')
APIC_INST_NAME_TLS_CLIENT_PROFILE_URL=$(apic tls-client-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG  | grep eem-tls-client-profile | awk '{print$2}')
DEFAULT_TLS_SERVER_PROFILE_URL=$(apic tls-server-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | grep tls-server-profile-default | awk '{print$2}')
# Get event-gateway service integration_url
INTEGRATION_URL=$(apic integrations:get event-gateway --subcollection gateway-service --server $APIC_MGMT_SERVER --format json --fields url | awk '{print$3}')
( echo "cat <<EOF" ; cat templates/template-eem-apic-event-gateway.json ;) | \
    EEM_MANAGER_APIC_HOST=${EEM_MANAGER_APIC_HOST} \
    EEM_GATEWAY_RT_HOST=${EEM_GATEWAY_RT_HOST} \
    APIC_INST_NAME_TLS_CLIENT_PROFILE_URL=${APIC_INST_NAME_TLS_CLIENT_PROFILE_URL} \
    DEFAULT_TLS_SERVER_PROFILE_URL=${DEFAULT_TLS_SERVER_PROFILE_URL} \
    INTEGRATION_URL=${INTEGRATION_URL} \
    sh > eem-apic-event-gateway.json
GTWYSVCS_LIST=$(apic gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --availability-zone $APIC_AVAILABILITY_ZONE | awk '$1 == "eem-gateway-service" { ++count } END { print count }')
if [ -z $GTWYSVCS_LIST ] 
then 
    echo "Creating Gateway Service for EEM..."
    apic gateway-services:create --server $APIC_MGMT_SERVER --availability-zone $APIC_AVAILABILITY_ZONE --org $APIC_ADMIN_ORG --format json eem-apic-event-gateway.json
else
    echo "Gateway Service for EEM already exists."
fi
#
echo "Cleaning up temp files..."
rm -f eem-apic-event-gateway.json
rm -f Integration.json
echo "Event Endpoint Manager has been registered with APIC."