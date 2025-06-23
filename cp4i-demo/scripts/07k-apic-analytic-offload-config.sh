#!/bin/sh
echo "Creating Kafka configuration for APIC Analytics offloading"
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
ES_USER_ID='apic-analytics-offload-user'
########################
# CREATE CONFIGURATION #
########################
#oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.password
#TRUSTSTORE_PWD=`cat ca.password`
TRUSTSTORE_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.p12
keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore es-cert.jks  -deststoretype JKS -srcstorepass ${TRUSTSTORE_PWD} -deststorepass ${TRUSTSTORE_PWD} -srcalias ca.crt -destalias ca.crt -noprompt
echo "Creating Kafka TrustStore Cert..."
oc create secret generic apim-demo-offload-a7s-certificate -n tools --from-file=es-cert.jks=./es-cert.jks
( echo "cat <<EOF" ; cat templates/template-apic-offload-kafka-secret.yaml ;) | \
    TRUSTSTORE_PWD=${TRUSTSTORE_PWD} \
    sh > apic-offload-kafka-secret.yaml
echo "Creating Kafka TrustStore Secret..."
oc apply -f apic-offload-kafka-secret.yaml -n tools
echo "Preparing patch file for Analytics..."
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.type} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
#oc extract secret/${ES_USER_ID} -n ${ES_NAMESPACE} --keys=password
#ES_USER_PWD=`cat password`
ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
( echo "cat <<EOF" ; cat templates/template-apic-offload-kafka-scram.yaml ;) | \
    ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
    ES_USER_PWD=${ES_USER_PWD} \
    sh > apic-offload-kafka-scram.yaml
oc patch apiconnectcluster apim-demo -n tools --type merge --patch-file apic-offload-kafka-scram.yaml
echo "Cleaning up temp files..."
#rm -f ca.password
rm -f ca.p12
rm -f ca.crt
rm -f es-cert.jks
rm -f apic-offload-kafka-secret.yaml
#rm -f password
rm -f apic-offload-kafka-scram.yaml
echo "APIC Analytics Offload with Kafka configuration has been created."
