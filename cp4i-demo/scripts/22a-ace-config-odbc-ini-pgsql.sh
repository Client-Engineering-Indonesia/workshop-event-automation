#!/bin/sh
echo "Building PGSQL ODBC Configuration"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-pgsql-odbc-ini"
CONFIG_TYPE="odbc"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="ODBC config to connect to PGSQL DB"
##########################
# PREPARE CONFIG CONTENT #
##########################
case "$CP4I_VER" in
    "16.1.0")
        ACE_VER='ace-12'
        ;;
    "16.1.1")
        ACE_VER='ace-13'
        ;;
    *)
        echo "CP4I_VER $CP4_VER is not valid."
        exit 1
        ;;
esac
( echo "cat <<EOF" ; cat templates/template-ace-pgsql-odbc.ini ;) | \
    ACE_VER=${ACE_VER} \
    sh > ace-pgsql-odbc.ini
CONFIG_DATA_BASE64=$(base64 -i ace-pgsql-odbc.ini | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-pgsql-odbc-ini.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-pgsql-odbc-ini.yaml
oc -n tools label configuration ace-pgsql-odbc-ini assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
rm -f ace-pgsql-odbc.ini
rm -f ace-config-pgsql-odbc-ini.yaml
echo "PGSQL ODBC Configuration has been created."
