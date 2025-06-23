#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
#APIC_PTL_URI=$(oc get portalcluster apim-demo-ptl -n tools -o jsonpath='{range .status.endpoints[?(@.name=="portalWeb")]}{.uri}{end}')
APIC_PTL_URI=$(oc get portalcluster apim-demo-ptl -n tools -o jsonpath='{.status.endpoints[?(@.name=="portalWeb")].uri}')
if [ "$CP4I_VER" = "16.1.0" ]
then 
    #APIC_CONSUMER_CATALOG_URI=$(oc get managementcluster apim-demo-mgmt -n tools -o jsonpath='{range .status.endpoints[?(@.name=="consumerCatalog")]}{.uri}{end}')
    APIC_CONSUMER_CATALOG_URI=$(oc get managementcluster apim-demo-mgmt -n tools -o jsonpath='{.status.endpoints[?(@.name=="consumerCatalog")].uri}')
else
    APIC_CONSUMER_CATALOG_URI=$APIC_PTL_URI
fi
echo "Setting APIC variables..."
if [ -z "$USER_NAME" ]
then
    APIC_PROVIDER_ORG='cp4i-demo-org'
else
    APIC_PROVIDER_ORG='tz-provider-org'
fi
echo "API Connect Portals CP4I Demo POrg..."
echo "Sandbox Catalog:"
echo "   UI URL: $APIC_CONSUMER_CATALOG_URI$APIC_PROVIDER_ORG/sandbox"
echo "Demo Catalog:"
echo "   UI URL: $APIC_PTL_URI$APIC_PROVIDER_ORG/demo"