#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-native-ha'
QMGR_NAMESPACE='cp4i-mq'
QMGR_CHANNEL="MTLS.SVRCONN"
##################################
# QUEUE MANAGER PRECONFIGURATION #
##################################
echo "Preconfiguring Queue Manager..."
echo " Create ConfigMap with MQ resources..."
oc apply -f resources/03j-qmgr-mqsc-ini-config-nha.yaml -n ${QMGR_NAMESPACE}
echo "Creating QMgr CA..."
oc apply -f resources/03h-qmgr-ss-issuer.yaml -n ${QMGR_NAMESPACE}
( echo "cat <<EOF" ; cat templates/template-mq-nha-ca-cert.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    sh > qmgr-ca-cert.yaml
oc apply -f qmgr-ca-cert.yaml -n ${QMGR_NAMESPACE}
( echo "cat <<EOF" ; cat templates/template-mq-nha-ca-issuer.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    sh > qmgr-ca-issuer.yaml
oc apply -f qmgr-ca-issuer.yaml -n ${QMGR_NAMESPACE}
echo "Creating Certificate Template..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
( echo "cat <<EOF" ; cat templates/template-mq-nha-certificate.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > mq-certificate.yaml
echo "Creating Certificate..."
oc apply -f mq-certificate.yaml
while ! oc wait --for=jsonpath='{.status.conditions[0].type}'=Ready \
      certificate/${QMGR_NAME}-selfsigned-cert -n ${QMGR_NAMESPACE} 2>/dev/null
do sleep 10; done
echo "Creating Route..."
MQ_CHANNEL_SNI=$(echo $QMGR_CHANNEL | tr '[:upper:]' '[:lower:]')
HOST_NAME="${MQ_CHANNEL_SNI//./2e-}.chl.mq.ibm.com"
( echo "cat <<EOF" ; cat templates/template-mq-tls-route.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    HOST_NAME=${HOST_NAME} \
    sh > mq-tls-route.yaml
oc create -f mq-tls-route.yaml
echo "Cleaning up temp file..."
rm -f qmgr-ca-cert.yaml
rm -f qmgr-ca-issuer.yaml
rm -f mq-certificate.yaml
rm -f mq-tls-route.yaml
echo "Queue Manager preconfiguration completed."