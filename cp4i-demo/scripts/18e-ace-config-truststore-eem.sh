#!/bin/sh
if [ -z "$EEM_APIC_INT" ]; then echo "EMM is not configured."; exit 1; fi;
echo "Building TrustStore Configuration"
###################
# INPUT VARIABLES #
###################
#APIC_INST_NAME='apim-demo'
EEM_GW_INST_NAME='eem-gw-demo'
#APIC_NAMESPACE='tools'
EEM_NAMESPACE='tools'
CONFIG_NAME="egw-cert.jks"
CONFIG_TYPE="truststore"
CONFIG_DESCRIPTION="JKS certificate for Event Endpoint Management Gateway"
CONFIG_NS="tools"
########################
# CREATE CONFIGURATION #
########################
#EGW_HOST=$(oc get route ${APIC_INST_NAME}-egw-event-gw-client -n ${APIC_NAMESPACE} -o jsonpath='{.spec.host}')
#EGW_HOST=$(oc get route eem-gw-demo-ibm-egw-rt -n ${APIC_NAMESPACE} -o jsonpath='{.spec.host}')
#EGW_HOST=$(oc get route ${EEM_GW_INST_NAME}-ibm-egw-rt -n ${EEM_NAMESPACE} -o jsonpath='{.spec.host}')
#echo -n | openssl s_client -connect $EGW_HOST:443 -servername $EGW_HOST -showcerts | openssl x509 > egw-cert.crt
#keytool -import -alias egwcert -file egw-cert.crt -keystore egw-cert.p12 -storetype pkcs12 -storepass password --noprompt
#keytool -importkeystore -srckeystore egw-cert.p12 -srcstoretype PKCS12 -destkeystore egw-cert.jks  -deststoretype JKS -srcstorepass password -deststorepass password -srcalias egwcert -destalias egwcert -noprompt
CONFIG_DATA_BASE64=$(base64 -i egw-cert.jks | tr -d '\n')
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-truststore.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-truststore.yaml
echo "Cleaning up temp files..."
#rm -f egw-cert.crt
#rm -f egw-cert.p12
#rm -f egw-cert.jks
rm -f ace-config-truststore.yaml
echo "TrustStore Configuration has been created."
