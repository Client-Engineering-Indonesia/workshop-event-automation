#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo "yq could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.1"; exit 1; fi;
read -p "Press <Enter> to execute script..."
##################
# INPUT VARIABLE #
##################
QMGR_DC1='london'
QMGR_DC2='rome'
MQ_VERSION='9.4.2.1-r2'
if [ -z "$OCP_CLUSTER_DOMAIN" ]
then
    OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
fi
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/32a-qmgr-nha-crr-instance.yaml ;) | \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    MQ_VERSION=${MQ_VERSION} \
    sh > 32-qmgr-nha-crr-instance.yaml
echo "Deploying Queue Manager instance..."
oc apply -f 32-qmgr-nha-crr-instance.yaml -n ${QMGR_DC1}
echo "Cleaning up temp file..."
rm -f 32-qmgr-nha-crr-instance.yaml
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/32b-qmgr-nha-crr-instance.yaml ;) | \
    OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
    MQ_VERSION=${MQ_VERSION} \
    sh > 32-qmgr-nha-crr-instance.yaml
echo "Deploying Queue Manager instance..."
oc apply -f 32-qmgr-nha-crr-instance.yaml -n ${QMGR_DC2}
echo "Cleaning up temp file..."
rm -f 32-qmgr-nha-crr-instance.yaml
echo "Done! Check progress..."