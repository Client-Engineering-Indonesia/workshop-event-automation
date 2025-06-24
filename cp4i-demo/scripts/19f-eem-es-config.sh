#!/bin/sh
# This script requires the oc and jq commands to be installed in your environment
# And before running the script you need to set an environment variable call "EEM_TOKEN" with the corresponding token, i.e. using this command:
# "export EEM_TOKEN=my-eem-token"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
echo "Event Endpoint Manager Configuration..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
##########################
# PREPARE CONFIG CONTENT #
##########################
oc extract secret/${EEM_INST_NAME}-ibm-eem-manager -n ${EEM_NAMESPACE} --keys=ca.crt
EEM_CERTIFICATE=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ca.crt)
#EEM_API_HOST=$(oc get eem ${EEM_INST_NAME} -n ${EEM_NAMESPACE} -o jsonpath='{range .status.endpoints[*]}{.name} {.uri}{"\n"}{end}' | awk '$1=="admin" {print $2}')
#EEM_UI_URL=$(oc get eem ${EEM_INST_NAME} -n ${EEM_NAMESPACE} -o jsonpath='{range .status.endpoints[*]}{.name} {.uri}{"\n"}{end}' | awk '$1=="ui" {print $2}')
#EEM_API_HOST=$(oc get eem ${EEM_INST_NAME} -n ${EEM_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="admin")].uri}')
#EEM_UI_URL=$(oc get eem ${EEM_INST_NAME} -n ${EEM_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="ui")].uri}')
EEM_API_HOST=$(oc get route ${EEM_INST_NAME}-ibm-eem-admin -n ${EEM_NAMESPACE} -o jsonpath={.spec.host})
EEM_UI_URL=$(oc get route ${EEM_INST_NAME}-ibm-eem-manager -n ${EEM_NAMESPACE} -o jsonpath={.spec.host})
( echo "cat <<EOF" ; cat templates/template-es-kafka-eem-configmap.yaml ;) | \
    ES_INST_NAME=${ES_INST_NAME} \
    ES_NAMESPACE=${ES_NAMESPACE} \
    EEM_INST_NAME=${EEM_INST_NAME} \
    EEM_API_HOST=${EEM_API_HOST} \
    EEM_CERTIFICATE=${EEM_CERTIFICATE} \
    EEM_UI_URL=${EEM_UI_URL} \
    sh > es-kafka-eem-configmap.yaml
oc apply -f es-kafka-eem-configmap.yaml
echo "Cleaning up temp files..."
rm -f ca.crt
rm -f es-kafka-eem-configmap.yaml
echo "Event Endpoint Manager has been configured."