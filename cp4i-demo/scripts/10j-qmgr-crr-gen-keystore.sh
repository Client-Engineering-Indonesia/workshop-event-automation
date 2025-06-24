#!/bin/sh
echo "Generate Key Store to connect to Queue Manager"
###################
# INPUT VARIABLES #
###################
QMGR_DCS=(london rome)
######################
# GENERATE KEY STORES #
######################
echo "Creating Key Store for CRR Queue Managers..."
for DC in "${QMGR_DCS[@]}"
do
    echo "Getting Keys from Secret..."
    oc extract secret/nhacrr-$DC-app-tls -n $DC --keys=ca.crt
    oc extract secret/nhacrr-$DC-app-tls -n $DC --keys=tls.crt
    oc extract secret/nhacrr-$DC-app-tls -n $DC --keys=tls.key
    echo "Creating P12 Key Store..."
    openssl pkcs12 -export -in tls.crt -inkey tls.key -certfile ca.crt -out artifacts/qmgr-server-tls-${DC}${QMGR_DC}.p12 -name "nhacrr-${DC}-app" -passout pass:password
    ( echo "cat <<EOF" ; cat templates/template-mq-crr-mqclient.ini ;) | \
        QMGR_DC_NAME=${DC}${QMGR_DC} \
        sh > artifacts/mqclient-$DC$QMGR_DC.ini    
    echo "Cleaning up temp file..."
    rm -f ca.crt
    rm -f tls.crt
    rm -f tls.key
done
echo "KeyStore has been created."