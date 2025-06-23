#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-rest-api'
QMGR_NAMESPACE='tools'
echo "Getting QMGR Host..."
QMGR_HOST="https://$(oc get route ${QMGR_NAME}-ibm-mq-web -n ${QMGR_NAMESPACE} --ignore-not-found -o jsonpath='{.spec.host}')"
if [[ ! -z "${QMGR_HOST}" ]]
then
    echo "Creating KEDA Trigger Authorization..."
    oc apply -f resources/91e-keda-trigger-auth.yaml -n tools
    echo "Preparing Scaled Object manifest..."
    ( echo "cat <<EOF" ; cat resources/91f-keda-scaled-object.yaml ;) | \
        QMGR_HOST=${QMGR_HOST} \
        sh > keda-scaled-object.yaml
    echo "Creating KEDA Scaled Object..."
    oc apply -f keda-scaled-object.yaml -n tools
    echo "Cleaning up temp files..."
    rm -f keda-scaled-object.yaml
    echo "KEDA resources have been configured."
else
    echo "QMGR ${QMGR_NAME} is not deployed in namespace ${QMGR_NAMESPACE}. Check and try again."
fi