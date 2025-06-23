#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
echo "Keycloak Configuration..."
###################
# INPUT VARIABLES #
###################
KEYCLOAK_URL="https://"$(oc get routes keycloak -n ibm-common-services -o jsonpath='{range .status.ingress[*]}{.routerName} {.host}{"\n"}{end}' | awk '$1=="default" {print $2}')"/"
KEYCLOAK_CLIENT_ID=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.username} | base64 -d)
#KEYCLOAK_CLIENT_ID=$(oc get secret cs-keycloak-initial-admin -n ibm-common-services -o jsonpath={.data.username} | base64 -d)
KEYCLOAK_CLIENT_SECRET=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.password} | base64 -d)
#KEYCLOAK_CLIENT_SECRET=$(oc get secret cs-keycloak-initial-admin -n ibm-common-services -o jsonpath={.data.password} | base64 -d)
#echo $KEYCLOAK_URL
#echo $KEYCLOAK_CLIENT_ID
#echo $KEYCLOAK_CLIENT_SECRET
echo "Getting token..."
curl -X POST -s -k \
     --dump-header keycloak-api-header \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -d "username=${KEYCLOAK_CLIENT_ID}" \
     -d "password=${KEYCLOAK_CLIENT_SECRET}" \
     -d 'grant_type=password' \
     -d 'client_id=admin-cli' \
     --output keycloak-response-data.json \
     --write-out '%{response_code}\n' \
     $KEYCLOAK_URL/realms/cloudpak/protocol/openid-connect/token
TKN=$(jq -r '.access_token' keycloak-response-data.json)
#echo $TKN
echo "Invoking Keycloak Admin API"
curl -X GET -s -k \
     --dump-header keycloak-api-header \
     -H 'Accept: application/json' \
     -H "Authorization: Bearer $TKN" \
     --output keycloak-response-data.json \
     --write-out '%{response_code}\n' \
     $KEYCLOAK_URL/admin/realms/cloudpak/users
cat keycloak-api-header;echo
yq keycloak-response-data.json
#$KEYCLOAK_URL/admin/realms/cloudpak/users/8374c6da-e750-4ebb-a132-eecf1f1b66c2
#$KEYCLOAK_URL/admin/realms/cloudpak/groups/c2a97bcd-17dd-44a7-8874-785cf308f5cc
#curl -X POST -s -k \
#     --dump-header keycloak-api-header \
#     -H 'Accept: application/json' \
#     -H 'Content-Type: application/json' \
#     -H "Authorization: Bearer $TKN" \
#     --data @openldap.json \
#     --output keycloak-response-data.json \
#     --write-out '%{response_code}' \
#     $KEYCLOAK_URL/admin/realms/cloudpak/components
GROUP_NAME='test'
( echo "cat <<EOF" ; cat templates/template-keycloak-group.json ;) | \
GROUP_NAME=${GROUP_NAME} \
sh > keycloak-group.json
curl -X POST -s -k \
     --dump-header keycloak-api-header \
     -H 'Accept: application/json' \
     -H 'Content-Type: application/json' \
     -H "Authorization: Bearer $TKN" \
     --data @keycloak-group.json \
     --output keycloak-response-data.json \
     --write-out '%{response_code}' \
     $KEYCLOAK_URL/admin/realms/cloudpak/groups
cat keycloak-api-header;echo
yq keycloak-response-data.json
echo "Cleaning up temp files..."
rm -f keycloak-api-header
rm -f keycloak-response-data.json
rm -f keycloak-group.json
echo "Keycloak has been configured."