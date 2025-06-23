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
    echo "Creating secrets with ES credentials..."
    ES_USER_ID='knative-kafka-user'
    ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
    oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.crt
    oc create secret generic kafkasource-es-demo-auth \
        --from-file=ca.crt=ca.crt \
        --from-literal=password="${ES_USER_PWD}" \
        --from-literal=saslType="SCRAM-SHA-512" \
        --from-literal=user="${ES_USER_ID}"
    echo "Updating template with Bootsrap info..."
    ( echo "cat <<EOF" ; cat templates/template-knative-kafkasource-surveyadmin-sec.yaml ;) | \
        ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
        sh > knative-kafkasource-surveyadmin.yaml
    echo "Creating Knative Kafka Source resources..."
    oc apply -f knative-kafkasource-surveyadmin.yaml
    echo "Cleaning up temp files..."
    rm -f ca.crt
    rm -f knative-kafkasource-surveyadmin.yaml
    echo "Knative Kafka Source has been configured."
else
    echo "ES instance ${ES_INST_NAME} is not deployed in namespace ${ES_NAMESPACE}. Check and try again."
fi