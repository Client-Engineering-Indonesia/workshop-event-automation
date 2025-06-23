#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$GOOGLE_API_KEY" ]; then echo "GOOGLE_API_KEY not set, it must be provided on the command line."; exit 1; fi;
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
# Las Vegas location:
SURVEY_LATITUDE='36.10212330390405'
SURVEY_LONGITUDE='-115.174411774675'
echo "Getting Bootstrap information..."
ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' --ignore-not-found | awk '$1=="authsslsvc" {print $2}')
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' --ignore-not-found | awk '$1=="plain" {print $2}')
echo $ES_BOOTSTRAP_SERVER
if [[ ! -z "${ES_BOOTSTRAP_SERVER}" ]]
then
    ES_USER_ID='knative-kafka-user'
    ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
    TRUSTSTORE_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
    QRCODE_URL=$(kn service list surveyinputservice --no-headers -o jsonpath='{.items[0].status.url}')"/location.html"
    echo "Updating template with Bootsrap info..."
    ( echo "cat <<EOF" ; cat templates/template-knative-service-surveyadmin-sec.yaml ;) | \
        ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
        TRUSTSTORE_PWD=${TRUSTSTORE_PWD} \
        ES_USER_ID=${ES_USER_ID} \
        ES_USER_PWD=${ES_USER_PWD} \
        GOOGLE_API_KEY=${GOOGLE_API_KEY} \
        QRCODE_URL=${QRCODE_URL} \
        SURVEY_LATITUDE=${SURVEY_LATITUDE} \
        SURVEY_LONGITUDE=${SURVEY_LONGITUDE} \
        sh > knative-service-surveyadmin.yaml
    echo "Creating Survey Admin Service..."
    oc apply -f knative-service-surveyadmin.yaml
    echo "Cleaning up temp files..."
    rm -f knative-service-surveyadmin.yaml
    echo "Survey Input Service has been deployed."
else
    echo "ES instance ${ES_INST_NAME} is not deployed in namespace ${ES_NAMESPACE}. Check and try again."
fi