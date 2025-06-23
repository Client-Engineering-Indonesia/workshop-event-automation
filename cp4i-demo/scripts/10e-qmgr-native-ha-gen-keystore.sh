#!/bin/sh
echo "Generate Key Store to connect to Queue Manager"
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-native-ha'
QMGR_NAMESPACE='cp4i-mq'
######################
# GENERATE KEY STORE #
######################
echo "Getting Keys from Secret..."
oc extract secret/${QMGR_NAME}-tls-secret -n ${QMGR_NAMESPACE} --keys=ca.crt
oc extract secret/${QMGR_NAME}-tls-secret -n ${QMGR_NAMESPACE} --keys=tls.crt
oc extract secret/${QMGR_NAME}-tls-secret -n ${QMGR_NAMESPACE} --keys=tls.key
echo "Creating P12 Key Store..."
openssl pkcs12 -export -in tls.crt -inkey tls.key -certfile ca.crt -out artifacts/qmgr-server-nha-tls.p12 -name "${QMGR_NAME}-app" -passout pass:password
( echo "cat <<EOF" ; cat templates/template-mq-nha-mqclient.ini ;) | \
    QMGR_CCDT_NAME='mqnhaccdt' \
    QMGR_CERT_NAME='qmgr-server-nha-tls' \
    sh > artifacts/mqclient-nha.ini
echo "Cleaning up temp file..."
rm -f ca.crt
rm -f tls.crt
rm -f tls.key
echo "KeyStore has been created."