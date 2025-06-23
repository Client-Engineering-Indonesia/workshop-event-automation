#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
INT_SRVR_NAME='jgr-multi-bar-mq'
INT_SRVR_NAMESPACE='tools'
#######################################
# INTEGRATION SERVER PRECONFIGURATION #
#######################################
echo "Preconfiguring Integration Server..."
oc apply -f resources/00-gitops-clusterissuer.yaml
echo "Creating Certificate Template..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
( echo "cat <<EOF" ; cat templates/template-ace-ir-certificate.yaml ;) | \
    INT_SRVR_NAME=${INT_SRVR_NAME} \
    INT_SRVR_NAMESPACE=${INT_SRVR_NAMESPACE} \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    sh > ace-ir-certificate.yaml
echo "Creating Certificate..."
oc apply -f ace-ir-certificate.yaml
echo "Cleaning up temp files..."
rm -f ace-ir-certificate.yaml
echo "Integration Server preconfiguration completed."