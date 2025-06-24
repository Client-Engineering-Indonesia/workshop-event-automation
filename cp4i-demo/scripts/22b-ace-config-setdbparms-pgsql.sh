#!/bin/sh
PGSQL_INST_NAME='pgsqldemo'
PGSQL_NS='pgsql'
PGSQL_USER_NAME='demouser'
PGSQL_USER_PWD=$(oc get secret ${PGSQL_INST_NAME}-pguser-${PGSQL_USER_NAME} -n ${PGSQL_NS} -o jsonpath='{.data.password}' | base64 -d)
echo "Building SetDBParms Configuration for PGSQL DB"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-pgsql-db-secid"
CONFIG_TYPE="setdbparms"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect to PGSQL DB"
##########################
# PREPARE CONFIG CONTENT #
##########################
cat <<EOF >ace-setdbparms-data-pgsql.txt
odbc::pgsqldemo $PGSQL_USER_NAME $PGSQL_USER_PWD
EOF
CONFIG_DATA_BASE64=$(base64 -i ace-setdbparms-data-pgsql.txt | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-setdbparms-pgsql.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-setdbparms-pgsql.yaml
oc -n tools label configuration ace-pgsql-db-secid assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
rm -f ace-setdbparms-data-pgsql.txt
rm -f ace-config-setdbparms-pgsql.yaml
echo "SetDBParms Configuration for PGSQL DB has been created."
