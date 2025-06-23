#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
echo "Getting Bootstrap information..."
ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' --ignore-not-found | awk '$1=="authsslsvc" {print $2}')
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' --ignore-not-found | awk '$1=="plain" {print $2}')
echo $ES_BOOTSTRAP_SERVER
if [[ ! -z "${ES_BOOTSTRAP_SERVER}" ]]
then
    ES_USER_ID='knative-kafka-user'
    ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
    TRUSTSTORE_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
    oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.p12
    keytool -importkeystore -srckeystore ca.p12 -srcstoretype PKCS12 -destkeystore es-cert.jks  -deststoretype JKS -srcstorepass ${TRUSTSTORE_PWD} -deststorepass ${TRUSTSTORE_PWD} -srcalias ca.crt -destalias ca.crt -noprompt
    echo "Creating Kafka TrustStore Cert..."
    oc create secret generic knative-service-es-demo-auth --from-file=es-cert.jks=./es-cert.jks
    echo "Updating template with Bootsrap info..."
    ( echo "cat <<EOF" ; cat templates/template-knative-service-surveyinput-sec.yaml ;) | \
        ES_BOOTSTRAP_SERVER="SASL_SSL://${ES_BOOTSTRAP_SERVER}" \
        TRUSTSTORE_PWD=${TRUSTSTORE_PWD} \
        ES_USER_ID=${ES_USER_ID} \
        ES_USER_PWD=${ES_USER_PWD} \
        sh > knative-service-surveyinput.yaml
    echo "Creating Survey Input Service..."
    oc apply -f knative-service-surveyinput.yaml
    echo "Cleaning up temp files..."
    rm -f ca.p12
    rm -f es-cert.jks
    rm -f knative-service-surveyinput.yaml
    echo "Survey Input Service has been deployed."
else
    echo "ES instance ${ES_INST_NAME} is not deployed in namespace ${ES_NAMESPACE}. Check and try again."
fi