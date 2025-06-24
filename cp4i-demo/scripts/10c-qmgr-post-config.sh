#!/bin/sh
echo "Building CCDT to connect to Queue Manager"
###################
# INPUT VARIABLES #
###################
QMGR_NAMESPACE='tools'
QMGR_NAME='qmgr-demo'
QMGR_INT_NAME='QMGRDEMO'
QMGR_CHANNEL="EXTAPP.TO.MQ"
QMGR_HOST=$(oc get route ${QMGR_NAME}-ibm-mq-qm -n ${QMGR_NAMESPACE} -o jsonpath="{.spec.host}")
########################
# CREATE CCDT #
########################
( echo "cat <<EOF" ; cat templates/template-mq-ccdt.json ;) | \
    QMGR_CHANNEL=${QMGR_CHANNEL} \
    QMGR_HOST=${QMGR_HOST} \
    QMGR_INT_NAME=${QMGR_INT_NAME} \
    sh > artifacts/MQCCDT.JSON
echo "CCDT has been created."