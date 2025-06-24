#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
echo "Configuring API Gateway to be used for WatsonX by EA..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_AVAILABILITY_ZONE='availability-zone-default'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
############################
# DEPLOY EXTRA API GATEWAY #
############################
oc apply -f resources/13e-apic-dp-gw-self-signed-issuer.yaml
#
APIC_HOST=$(oc get route ${APIC_INST_NAME}-gw-gateway -n ${APIC_NAMESPACE} -o jsonpath='{.spec.host}')
( echo "cat <<EOF" ; cat templates/template-apic-cert-ea-watsonx.yaml ;) | \
    APIC_HOST=${APIC_HOST} \
    sh > apic-cert-ea-watsonx.yaml
oc apply -f apic-cert-ea-watsonx.yaml
#
echo "Login to APIC with CMC Admin User..."
apic client-creds:clear
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
### Create keystore
oc extract secret/apic-gateway-tls -n ${APIC_NAMESPACE} --keys=tls.crt
oc extract secret/apic-gateway-tls -n ${APIC_NAMESPACE} --keys=tls.key
cat tls.crt tls.key > tls-combined.pem
APIC_CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tls-combined.pem)
( echo "cat <<EOF" ; cat templates/template-ea-watsonx-apic-keystore.json ;) | \
    APIC_INST_NAME=${APIC_INST_NAME} \
    APIC_CERT=${APIC_CERT} \
    sh > ea-watsonx-apic-keystore.json
KEYS_LIST=$(apic keystores:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '$1 == "ea-watsonx-keystore" { ++count } END { print count }')
if [ -z $KEYS_LIST ] 
then 
    echo "Creating KeyStore for API Gateway Service with WatsonX..."
    apic keystores:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json ea-watsonx-apic-keystore.json    
else
    echo "KeyStore for API Gateway Service already exists."
fi
KEYSTORE_URL=$(apic keystores:get ea-watsonx-keystore --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '{print$3}')
( echo "cat <<EOF" ; cat templates/template-ea-watsonx-tls-server-profile.json ;) | \
    KEYSTORE_URL=${KEYSTORE_URL} \
    sh > ea-watsonx-tls-server-profile.json
TLS_SP_LIST=$(apic tls-server-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '$1 == "ea-watsonx-tls-server-profile:1.0.0" { ++count } END { print count }')
if [ -z $TLS_SP_LIST ] 
then 
    echo "Creating TLS Server Profile for WatsonX..."
    apic tls-server-profiles:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json ea-watsonx-tls-server-profile.json
else
    echo "TLS Server Profile for WatsonX already exists."
fi
TLS_SERVER_PROFILE_URL=$(apic tls-server-profiles:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json ea-watsonx-tls-server-profile:1.0.0 | awk '{print$3}') 
( echo "cat <<EOF" ; cat templates/template-apic-api-gateway-settings.json ;) | \
    TLS_SERVER_PROFILE_URL=${TLS_SERVER_PROFILE_URL} \
    sh > apic-api-gateway-settings.json
apic gateway-services:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --availability-zone $APIC_AVAILABILITY_ZONE api-gateway-service apic-api-gateway-settings.json
#
echo "Cleaning up temp files..."
rm -f apic-cert-ea-watsonx.yaml 
rm -f tls.crt
rm -f tls.key
rm -f tls-combined.pem
rm -f ea-watsonx-apic-keystore.json
rm -f ea-watsonx-keystore.yaml
rm -f ea-watsonx-tls-server-profile.json
rm -f ea-watsonx-tls-server-profile_1.0.0.json
rm -f apic-api-gateway-settings.json
echo "API Gateway has been deployed."