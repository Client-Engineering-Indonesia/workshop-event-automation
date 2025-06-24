#!/bin/sh
echo "Building CCDT to connect to Queue Manager"
###################
# INPUT VARIABLES #
###################
QMGR_DCS=(london rome)
QMGR_NAME='exampleqm'
QMGR_INT_NAME='EXAMPLEQM'
QMGR_CHANNEL_BASE="MTLS.SVRCONN."
###############
# CREATE CCDT #
###############
echo "Creating CCDTs for CRR Queue Managers..."
for DC in "${QMGR_DCS[@]}"
do
    QMGR_HOST=$(oc get route ${QMGR_NAME}-ibm-mq-qm -n $DC -o jsonpath="{.spec.host}")
    QMGR_DC_NAME=$(echo $DC | tr '[:lower:]' '[:upper:]')
    QMGR_CHANNEL=${QMGR_CHANNEL_BASE}${QMGR_DC_NAME}
    QMGR_CERT_LABEL="nhacrr-$DC-app"
    ( echo "cat <<EOF" ; cat templates/template-mq-crr-ccdt.json ;) | \
        QMGR_CHANNEL=${QMGR_CHANNEL} \
        QMGR_HOST=${QMGR_HOST} \
        QMGR_INT_NAME=${QMGR_INT_NAME} \
        QMGR_CERT_LABEL=${QMGR_CERT_LABEL} \
        sh > artifacts/mqcrrccdt-$DC$QMGR_DC.json
done
echo "CCDTs have been created."