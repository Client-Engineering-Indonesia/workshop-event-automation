#!/bin/sh
if [ -z "$EEM_APIC_INT" ]; then echo "EMM is not configured."; exit 1; fi;
echo "Building SetDBParms Configuration for ES"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-eem-gateway-secid"
CONFIG_TYPE="setdbparms"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect using SCRAM to ES Demo Cluster"
##########################
# PREPARE CONFIG CONTENT #
##########################
EEM_USER_ID=$(jq -r '.client_id' "artifacts/CP4I-Demo-App.json")
EEM_USER_PWD=$(jq -r '.client_secret' "artifacts/CP4I-Demo-App.json")
cat <<EOF >ace-setdbparms-data-eem-gateway.txt
truststore::truststorePass dummy password
kafka::eemegwSecId $EEM_USER_ID $EEM_USER_PWD
EOF
CONFIG_DATA_BASE64=$(base64 -i ace-setdbparms-data-eem-gateway.txt | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-setdbparms-eem-gateway.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-setdbparms-eem-gateway.yaml
echo "Cleaning up temp files..."
rm -f ace-setdbparms-data-eem-gateway.txt
rm -f ace-config-setdbparms-eem-gateway.yaml
echo "SetDBParms Configuration for ES has been created."
