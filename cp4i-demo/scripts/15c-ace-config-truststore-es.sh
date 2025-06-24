#!/bin/sh
echo "Building TrustStore Configuration"
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
CONFIG_NAME="es-cert.p12"
CONFIG_TYPE="truststore"
CONFIG_DESCRIPTION="PKCS12 certificate for Event Streams instance es-demo"
CONFIG_NS="tools"
########################
# CREATE CONFIGURATION #
########################
#oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.password
#TRUSTSTORE_PWD=`cat ca.password`
TRUSTSTORE_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.p12
cp ca.p12 es-cert.p12
keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore es-cert.jks  -deststoretype JKS -srcstorepass ${TRUSTSTORE_PWD} -deststorepass ${TRUSTSTORE_PWD} -srcalias ca.crt -destalias ca.crt -noprompt
CONFIG_DATA_BASE64=$(base64 -i es-cert.p12 | tr -d '\n')
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-truststore.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-truststore.yaml
oc -n tools label configuration es-cert.p12 assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
#rm -f ca.password
rm -f ca.p12
rm -f es-cert.jks
rm -f es-cert.p12
rm -f ace-config-truststore.yaml
echo "TrustStore Configuration has been created."
