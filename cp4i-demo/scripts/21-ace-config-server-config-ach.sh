#!/bin/sh
echo "Building Server Conf Configuration for ACH Flows..."
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="jgr-default-qmgr"
CONFIG_TYPE="serverconf"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Default QMgr for ACH Flows"
CONFIG_DATA_BASE64=$(base64 -i templates/template-ace-server-config-ach-hl7.yaml | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-server-conf.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-server-conf.yaml
echo "Cleaning up temp files..."
rm -f ace-config-server-conf.yaml
echo "Server Conf Configuration has been created."
