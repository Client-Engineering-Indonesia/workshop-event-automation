#!/bin/sh
echo "Generate Key Store to connect to Queue Manager"
###################
# INPUT VARIABLES #
###################
QMGR_NAME='qmgr-demo'
QMGR_NAMESPACE='tools'
######################
# GENERATE KEY STORE #
######################
oc extract secret/${QMGR_NAME}-tls-secret -n ${QMGR_NAMESPACE} --keys=tls.crt
oc extract secret/${QMGR_NAME}-tls-secret -n ${QMGR_NAMESPACE} --keys=tls.key
openssl pkcs12 -export -in tls.crt -inkey tls.key -out qmgr-server-tls.p12 -name "qmgr server pkcs12" -passout pass:password
keytool -importkeystore -srckeystore qmgr-server-tls.p12 -srcstoretype PKCS12 -srcstorepass password -destkeystore artifacts/mqexplorerts.jks -deststoretype JKS -deststorepass password
runmqakm -keydb -create -db artifacts/mqclientkey.kdb -pw password -type cms -stash
runmqakm -cert -add -db artifacts/mqclientkey.kdb -label mqservercert -file tls.crt -format ascii -stashed
rm -f tls.crt
rm -f tls.key
rm -f qmgr-server-tls.p12
echo "KeyStore has been created."