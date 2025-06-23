#!/bin/sh
# Before running the script you need to set up the following environment variables related to your SF account:
# "SF_USER", "SF_PWD", "SF_CLIENT_ID", "SF_CLIENT_SECRET", "SF_LOGIN_URL" using these commands: 
# "export SF_USER=my-sf-user-id"
# "export SF_PWD=my-sf-password"
# "export SF_CLIENT_ID=my-sf-client-id"
# "export SF_CLIENT_SECRET=my-sf-client-secret"
# "export SF_LOGIN_URL=my-sf-login-url"
if [ -z "$SF_USER" ]; then echo "SF_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$SF_PWD" ]; then echo "SF_PWD not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$SF_CLIENT_ID" ]; then echo "SF_CLIENT_ID not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$SF_CLIENT_SECRET" ]; then echo "SF_CLIENT_SECRET not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$SF_LOGIN_URL" ]; then echo "SF_LOGIN_URL not set, it must be provided on the command line."; exit 1; fi;
echo "SF_USER is set to" $SF_USER
echo "SF_PWD is set to" $SF_PWD
echo "SF_CLIENT_ID is set to" $SF_CLIENT_ID
echo "SF_CLIENT_SECRET is set to" $SF_CLIENT_SECRET
echo "SF_LOGIN_URL is set to" $SF_LOGIN_URL
read -p "Press <Enter> to execute script..."
echo "Building Account Configuration for SalesForce"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-sf-designer-account"
CONFIG_TYPE="accounts"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect to SF from Designer Flow"
ACCOUNT_NAME="JGRSFAcct"
##########################
# PREPARE CONFIG CONTENT #
##########################
( echo "cat <<EOF" ; cat templates/template-ace-config-account-sf.yaml ;) | \
    ACCOUNT_NAME=${ACCOUNT_NAME} \
    SF_USER=${SF_USER} \
    SF_PWD=${SF_PWD} \
    SF_CLIENT_ID=${SF_CLIENT_ID} \
    SF_CLIENT_SECRET=${SF_CLIENT_SECRET} \
    SF_LOGIN_URL=${SF_LOGIN_URL} \
    sh > ace-config-account-sf.yaml
CONFIG_DATA_BASE64=$(base64 -i ace-config-account-sf.yaml | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-accounts-designer.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-accounts-designer.yaml
oc -n tools label configuration ace-sf-designer-account assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
rm -f ace-config-account-sf.yaml
rm -f ace-config-accounts-designer.yaml
echo "Account Configuration for SalesForce has been created."
