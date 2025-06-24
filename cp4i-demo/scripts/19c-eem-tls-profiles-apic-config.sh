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
APIC_JWKS_URL=$(oc get apiconnectcluster $APIC_INST_NAME -n $APIC_NAMESPACE -ojsonpath='{.status.endpoints[?(@.name=="jwksUrl")].uri}')
APIC_PLATFORM_API=$(oc get apiconnectcluster $APIC_INST_NAME -n $APIC_NAMESPACE -ojsonpath='{.status.endpoints[?(@.name=="platformApi")].uri}' | cut -b 9- | cut -d/ -f1)
echo -n | openssl s_client -connect $APIC_PLATFORM_API:443 -servername $APIC_PLATFORM_API -showcerts | openssl x509 > ${APIC_INST_NAME}-platform-api.pem
if [ $(oc get secrets -n $APIC_NAMESPACE | grep ${APIC_INST_NAME}-cpd | wc -l) -eq 0 ]
then
    echo "Creating Secret for EEM Gateway Service..."
    oc create secret generic ${APIC_INST_NAME}-cpd --from-file=ca.crt=./${APIC_INST_NAME}-platform-api.pem -n $APIC_NAMESPACE
else
    echo "Secret for EEM Gateway Service already exists."
fi 
oc get EventEndpointManagement eem-demo-mgr -n tools -o json \
  | jq --arg APIC_INST_NAME $APIC_INST_NAME \
       --arg APIC_JWKS_URL $APIC_JWKS_URL \
  '.spec.manager.apic.jwks += {"endpoint": ($APIC_JWKS_URL)} | 
  .spec.manager.apic += {"clientSubjectDN":"CN=ingress-ca"} | 
  .spec.manager.tls += {"trustedCertificates":[{"certificate":"ca.crt","secretName":($APIC_INST_NAME + "-cpd")}]}' \
  | oc apply -f -
oc get secret ${APIC_INST_NAME}-ingress-ca -n ${APIC_NAMESPACE} -o jsonpath="{.data.ca\.crt}" | base64 -D > ${APIC_INST_NAME}-ca.pem
oc get secret ${APIC_INST_NAME}-ingress-ca -n ${APIC_NAMESPACE} -o jsonpath="{.data.tls\.crt}" | base64 -D > ${APIC_INST_NAME}-tls-crt.pem
oc get secret ${APIC_INST_NAME}-ingress-ca -n ${APIC_NAMESPACE} -o jsonpath="{.data.tls\.key}" | base64 -D > ${APIC_INST_NAME}-tls-key.pem
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
#################
# LOGIN TO APIC #
#################
echo "Login to APIC with CMC Admin User..."
apic client-creds:clear
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
### Create keystore
cat $APIC_INST_NAME-tls-crt.pem $APIC_INST_NAME-tls-key.pem > $APIC_INST_NAME-tls-combined.pem
APIC_CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $APIC_INST_NAME-tls-combined.pem)
( echo "cat <<EOF" ; cat templates/template-eem-apic-keystore.json ;) | \
    APIC_INST_NAME=${APIC_INST_NAME} \
    APIC_CERT=${APIC_CERT} \
    sh > eem-apic-keystore.json
KEYS_LIST=$(apic keystores:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '$1 == "eem-keystore" { ++count } END { print count }')
if [ -z $KEYS_LIST ] 
then 
    echo "Creating KeyStore for EEM Gateway Service..."
    apic keystores:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json eem-apic-keystore.json
else
    echo "KeyStore for EEM Gateway Service already exists."
fi
### Create Truststore
APIC_CERT=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $APIC_INST_NAME-ca.pem)
( echo "cat <<EOF" ; cat templates/template-eem-apic-truststore.json ;) | \
    APIC_INST_NAME=${APIC_INST_NAME} \
    APIC_CERT=${APIC_CERT} \
    sh > eem-apic-truststore.json
KEYS_LIST=$(apic truststores:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '$1 == "eem-truststore" { ++count } END { print count }')
if [ -z $KEYS_LIST ] 
then 
    echo "Creating TrustStore for EEM Gateway Service..."
    apic truststores:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json eem-apic-truststore.json
else
    echo "TrustStore for EEM Gateway Service already exists."
fi
### Create TLS-Client-Profile
KEYSTORE_URL=$(apic keystores:get eem-keystore --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '{print$3}')
TRUSTSTORE_URL=$(apic truststores:get eem-truststore --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '{print$3}')
( echo "cat <<EOF" ; cat templates/template-eem-apic-tls-client-profile.json ;) | \
    KEYSTORE_URL=${KEYSTORE_URL} \
    TRUSTSTORE_URL=${TRUSTSTORE_URL} \
    sh > eem-apic-tls-client-profile.json
TLSCPS_LIST=$(apic tls-client-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG | awk '$1 == "eem-tls-client-profile:1.0.0" { ++count } END { print count }')
if [ -z $TLSCPS_LIST ] 
then 
    echo "Creating TLS Client Profile for EEM Gateway Service..."
    apic tls-client-profiles:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json eem-apic-tls-client-profile.json
else
    echo "TLS Client Profile for EEM Gateway Service already exists."
fi
echo "Cleaning up temp files..."
rm -f ${APIC_INST_NAME}-platform-api.pem
rm -f ${APIC_INST_NAME}-ca.pem
rm -f ${APIC_INST_NAME}-tls-crt.pem
rm -f ${APIC_INST_NAME}-tls-key.pem
rm -f ${APIC_INST_NAME}-tls-combined.pem
rm -f eem-apic-keystore.json
rm -f eem-apic-truststore.json
rm -f eem-apic-tls-client-profile.json
#rm -f eem-apic-event-gateway.json
rm -f eem-keystore.yaml
rm -f eem-truststore.yaml
#rm -f Integration.json
echo "Event Endpoint Manager has been registered with APIC."