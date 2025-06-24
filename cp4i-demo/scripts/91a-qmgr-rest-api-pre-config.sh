#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-rest-api'
QMGR_NAMESPACE='tools'
##################################
# QUEUE MANAGER PRECONFIGURATION #
##################################
echo "Preconfiguring Queue Manager..."
oc apply -f resources/00-gitops-clusterissuer.yaml
echo "Creating Certificate Template..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
( echo "cat <<EOF" ; cat templates/template-mq-certificate-alt.yaml ;) | \
    QMGR_NAME=${QMGR_NAME} \
    QMGR_NAMESPACE=${QMGR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > mq-certificate.yaml
echo "Creating Certificate..."
oc apply -f mq-certificate.yaml
echo "Cleaning up temp files..."
rm -f mq-certificate.yaml
echo "Queue Manager preconfiguration completed."