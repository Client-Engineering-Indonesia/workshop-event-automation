#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
######################
# SET APIC VARIABLES #
######################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
echo "Getting info..."
#APIC_MGMT_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="apiManager")]}{.uri}{end}')
APIC_MGMT_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="apiManager")].uri}')
#APIC_MGMT_SERVER=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="platformApi")]}{.uri}{end}')
APIC_MGMT_SERVER=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="platformApi")].uri}')
#APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
#APIC_CM_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="admin")]}{.uri}{end}')
APIC_CM_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="admin")].uri}')
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath={.data.password} | base64 -d)
#APIC_A7S_AI_ENDPOINT=$(oc get AnalyticsCluster "${APIC_INST_NAME}-a7s" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="aiEndpoint")]}{.uri}{end}')
APIC_A7S_AI_ENDPOINT=$(oc get AnalyticsCluster "${APIC_INST_NAME}-a7s" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="aiEndpoint")].uri}')
#APIC_PTL_MGMT_ENDPOINT=$(oc get PortalCluster "${APIC_INST_NAME}-ptl" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="portalDirector")]}{.uri}{end}')
APIC_PTL_MGMT_ENDPOINT=$(oc get PortalCluster "${APIC_INST_NAME}-ptl" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="portalDirector")].uri}')
#APIC_PTL_WEB_ENDPOINT=$(oc get PortalCluster "${APIC_INST_NAME}-ptl" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="portalWeb")]}{.uri}{end}')
APIC_PTL_WEB_ENDPOINT=$(oc get PortalCluster "${APIC_INST_NAME}-ptl" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="portalWeb")].uri}')
#APIC_GW_MGMT_ENDPOINT=$(oc get GatewayCluster "${APIC_INST_NAME}-gw" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="gatewayManager")]}{.uri}{end}')
APIC_GW_MGMT_ENDPOINT=$(oc get GatewayCluster "${APIC_INST_NAME}-gw" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="gatewayManager")].uri}')
#APIC_GW_API_ENDPOINT=$(oc get GatewayCluster "${APIC_INST_NAME}-gw" -n $APIC_NAMESPACE -o jsonpath='{range .status.endpoints[?(@.name=="gateway")]}{.uri}{end}')
APIC_GW_API_ENDPOINT=$(oc get GatewayCluster "${APIC_INST_NAME}-gw" -n $APIC_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="gateway")].uri}')
#
echo
echo "APIC Manager info:"
echo "APIC Manager URL:" $APIC_MGMT_URL
echo "APIC Platform API to be used with apic cli:" ${APIC_MGMT_SERVER#https://}
echo "APIC Cloud Manager UI URL:" $APIC_CM_URL
echo "APIC admin user: admin"
echo "APIC admin password:" $APIC_ADMIN_PWD
echo
echo "APIC Analytics info:"
echo "APIC Analytics instance name: analytics-service"
echo "APIC Analytics ingestion endpoint:" $APIC_A7S_AI_ENDPOINT
echo
echo "APIC Portal info:"
echo "APIC Portal instance name: portal-service"
echo "APIC Portal management endpoint:" $APIC_PTL_MGMT_ENDPOINT
echo "APIC Portal website endpoint:" $APIC_PTL_WEB_ENDPOINT
echo
echo "APIC Gateway info:"
echo "APIC Gateway instance name: api-gateway-service"
echo "APIC Gateway management endpoint:" $APIC_GW_MGMT_ENDPOINT
echo "APIC Gateway API endpoint:" $APIC_GW_API_ENDPOINT
echo
