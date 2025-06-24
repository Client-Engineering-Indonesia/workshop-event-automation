#!/bin/sh
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
#if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
#echo "MAILTRAP_USER is set to" $MAILTRAP_USER
MAILTRAP_USER='mailpit-user'
#echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
MAILTRAP_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
#read -p "Press <Enter> to execute script..."
echo "Building SetDBParms Configuration for eMail Server"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-email-server-secid"
CONFIG_TYPE="setdbparms"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect to eMail Server MailTrap"
##########################
# PREPARE CONFIG CONTENT #
##########################
cat <<EOF >ace-setdbparms-data-email.txt
smtp::mailtrapsecid $MAILTRAP_USER $MAILTRAP_PWD
EOF
CONFIG_DATA_BASE64=$(base64 -i ace-setdbparms-data-email.txt | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-setdbparms-email.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-setdbparms-email.yaml
oc -n tools label configuration ace-email-server-secid assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
rm -f ace-setdbparms-data-email.txt
rm -f ace-config-setdbparms-email.yaml
echo "SetDBParms Configuration for eMail Server has been created."
