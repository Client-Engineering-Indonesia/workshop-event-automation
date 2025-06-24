#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo "yq could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
if [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.1"; exit 1; fi;
###################
# INPUT VARIABLES #
###################
QMGR_DCS=(london rome)
QMGR_DC1='london'
QMGR_DC2='rome'
QMGR_NAME='exampleqm'
QMGR_CHANNEL="MTLS.SVRCONN."
###################################
# QUEUE MANAGERS PRECONFIGURATION #
###################################
echo "Preconfiguring Queue Managers for CRR..."
OCP_CLUSTER_DOMAIN=$(oc get IngressController default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
for DC in "${QMGR_DCS[@]}"
do
    echo "Creating QMgr CA..."
    oc apply -f resources/03h-qmgr-ss-issuer.yaml -n $DC
    ( echo "cat <<EOF" ; cat templates/template-mq-crr-ca-cert.yaml ;) | \
        QMGR_LOCATION=${DC} \
        sh > qmgr-ca-cert.yaml
    oc apply -f qmgr-ca-cert.yaml -n $DC
    ( echo "cat <<EOF" ; cat templates/template-mq-crr-ca-issuer.yaml ;) | \
        QMGR_LOCATION=${DC} \
        sh > qmgr-ca-issuer.yaml
    oc apply -f qmgr-ca-issuer.yaml -n $DC
    echo "Cleaning up temp file..."
    rm -f qmgr-ca-cert.yaml
    rm -f qmgr-ca-issuer.yaml
    CERT_TEMPLATES=(ext int app)
    echo "Creating Certificate Template..."
    for CT in "${CERT_TEMPLATES[@]}"
    do
        ( echo "cat <<EOF" ; cat templates/template-mq-crr-cert-$CT.yaml ;) | \
            QMGR_LOCATION=${DC} \
            OCP_CLUSTER_DOMAIN=${OCP_CLUSTER_DOMAIN} \
            sh > mq-certificate.yaml
        echo "Creating Certificate..."
        oc apply -f mq-certificate.yaml -n $DC
        echo "Cleaning up temp file..."
        rm -f mq-certificate.yaml
    done
    MQ_CHANNEL_SNI=$(echo $QMGR_CHANNEL | tr '[:upper:]' '[:lower:]')
    HOST_NAME="${MQ_CHANNEL_SNI//./2e-}${DC}.chl.mq.ibm.com"
    ( echo "cat <<EOF" ; cat templates/template-mq-tls-route.yaml ;) | \
        QMGR_NAME=${QMGR_NAME} \
        QMGR_NAMESPACE=${DC} \
        HOST_NAME=${HOST_NAME} \
        sh > mq-tls-route.yaml
    echo "Creating Route..."
    oc create -f mq-tls-route.yaml
    echo "Cleaning up temp file..."
    rm -f mq-tls-route.yaml
done
echo "Copy External Certificates..."
echo "Waiting for $QMGR_DC1 Ext Cert to be ready..."
while ! oc wait --for=jsonpath='{.status.conditions[0].type}'=Ready \
    certificate/nhacrr-$QMGR_DC1-ext -n \
    $QMGR_DC1 2>/dev/null; do sleep 30; done
oc get secret nhacrr-$QMGR_DC1-ext-tls -n $QMGR_DC1 -o yaml > artifacts/nhacrr-$QMGR_DC1$QMGR_DC-ext-tls.yaml
yq -i 'del(.metadata.creationTimestamp, .metadata.namespace, .metadata.resourceVersion, .metadata.uid)' \
    artifacts/nhacrr-$QMGR_DC1$QMGR_DC-ext-tls.yaml
if [ -z "$QMGR_DC" ]
then
    echo "Creating secret in $QMGR_DC1"
    oc apply -f artifacts/nhacrr-$QMGR_DC1-ext-tls.yaml -n $QMGR_DC2
fi
echo "Waiting for $QMGR_DC2 Ext Cert to be ready..."
while ! oc wait --for=jsonpath='{.status.conditions[0].type}'=Ready \
    certificate/nhacrr-$QMGR_DC2-ext -n \
    $QMGR_DC2 2>/dev/null; do sleep 30; done
oc get secret nhacrr-$QMGR_DC2-ext-tls -n $QMGR_DC2 -o yaml > artifacts/nhacrr-$QMGR_DC2$QMGR_DC-ext-tls.yaml
yq -i 'del(.metadata.creationTimestamp, .metadata.namespace, .metadata.resourceVersion, .metadata.uid)' \
    artifacts/nhacrr-$QMGR_DC2$QMGR_DC-ext-tls.yaml
if [ -z "$QMGR_DC" ]
then
    echo "Creating secret in $QMGR_DC1"
    oc apply -f artifacts/nhacrr-$QMGR_DC2-ext-tls.yaml -n $QMGR_DC1
fi
echo "Cleaning up temp file..."
rm -f artifacts/nhacrr-$QMGR_DC1-ext-tls.yaml
rm -f artifacts/nhacrr-$QMGR_DC2-ext-tls.yaml
echo "Queue Managers preconfiguration for CRR completed."