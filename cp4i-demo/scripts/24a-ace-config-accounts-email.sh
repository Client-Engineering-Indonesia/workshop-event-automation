#!/bin/sh
echo "Building Account Configuration for MailPit"
###################
# INPUT VARIABLES #
###################
ACCOUNT_NAME="JGRMailPitAcct"
MAILPIT_USER="admin@cp4i.demo.net"
MAILPIT_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
MAILPIT_URL="mailpit-smtp.mailpit.svc.cluster.local:1025"
CONFIG_NAME="ace-email-designer-account"
CONFIG_TYPE="accounts"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect to MailPit from Designer Flow"
##########################
# PREPARE CONFIG CONTENT #
##########################
echo "Preparing Base64 data for Configuration..."
( echo "cat <<EOF" ; cat templates/template-ace-config-account-email.yaml ;) | \
    ACCOUNT_NAME=${ACCOUNT_NAME} \
    MAILPIT_USER=${MAILPIT_USER} \
    MAILPIT_PWD=${MAILPIT_PWD} \
    MAILPIT_URL=${MAILPIT_URL} \
    sh > ace-config-account-email.yaml
CONFIG_DATA_BASE64=$(base64 -i ace-config-account-email.yaml | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
echo "Preparing Configuration manifest file..."
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-accounts-designer.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-accounts-designer.yaml
echo "Cleaning up temp files..."
rm -f ace-config-account-email.yaml
rm -f ace-config-accounts-designer.yaml
echo "Account Configuration for MailPit has been created."
