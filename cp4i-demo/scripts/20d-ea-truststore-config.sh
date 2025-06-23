#!/bin/sh
echo "Creating TrustStore for Event Automation..."
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
EEM_GW_INST_NAME='eem-demo-gw'
EEM_NAMESPACE='tools'
APIC_NAMESPACE='tools'
# PREPARE TRUSTSTORE
echo "Adding Event Streams certificate..."
oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.crt
keytool -importcert -noprompt -alias eventstreams -file ca.crt -trustcacerts -keystore eventautomation.jks -storepass "eventautomationstore"
rm -f ca.crt
echo "Adding EEM certificate..."
oc extract secret/${EEM_GW_INST_NAME}-ibm-egw-cert -n ${EEM_NAMESPACE} --keys=ca.crt
keytool -importcert -noprompt -alias eventendpointmanagement -file ca.crt -trustcacerts -keystore eventautomation.jks -storepass "eventautomationstore"
if [ ! -z "$EA_WATSONX" ]
then
    echo "Adding APIC certificate..."
    rm -f ca.crt
    oc extract secret/apic-gateway-tls -n ${APIC_NAMESPACE} --keys=ca.crt
    keytool -importcert -noprompt -alias apic -file ca.crt -trustcacerts -keystore eventautomation.jks -storepass "eventautomationstore"
fi
oc create secret generic eventautomation-truststore -n tools --from-file=eventautomation.jks=./eventautomation.jks
#
echo "Cleaning up temp files..."
rm -f ca.crt
rm -f eventautomation.jks
echo "TrustStore for Event Automation has been created."
