#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
echo "Getting data for manifest..."
OCP_FQDN=$(oc get dnses.config.openshift.io cluster -o jsonpath='{.spec.baseDomain}')
CP4I_KC_CLIENT_ID=$(oc get integrationkeycloakclient -n ibm-common-services | grep integration | awk '{print $1}')
( echo "cat <<EOF" ; cat templates/template-ep-keycloak-client.yaml ;) | \
OCP_FQDN=${OCP_FQDN} \
CP4I_KC_CLIENT_ID=${CP4I_KC_CLIENT_ID} \
sh > ep-keycloak-client.yaml
echo "Creating Keycloak Client..."
oc apply -f ep-keycloak-client.yaml
echo "Cleaning up temp files..."
rm -f ep-keycloak-client.yaml
echo "EP Keycloak client created."