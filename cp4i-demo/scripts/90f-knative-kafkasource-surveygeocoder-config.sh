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
    echo "Updating template with Bootsrap info..."
    ( echo "cat <<EOF" ; cat templates/template-knative-kafkasource-surveygeocoder-sec.yaml ;) | \
        ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
        sh > knative-kafkasource-surveygeocoder.yaml
    echo "Creating Knative Kafka Source resources..."
    oc apply -f knative-kafkasource-surveygeocoder.yaml
    echo "Cleaning up temp files..."
    rm -f knative-kafkasource-surveygeocoder.yaml
    echo "Knative Kafka Source has been configured."
else
    echo "ES instance ${ES_INST_NAME} is not deployed in namespace ${ES_NAMESPACE}. Check and try again."
fi