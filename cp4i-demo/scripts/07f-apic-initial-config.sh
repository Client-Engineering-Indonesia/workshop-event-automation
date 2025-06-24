#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1" )
      ;;
   *)
      echo "This script is for CP4I v2023.4 or v16.1.*"
      exit 1
      ;;
esac
#echo "MAILTRAP_USER is set to" $MAILTRAP_USER
#echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
echo "Configuring APIC..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
#MAILTRAP_HOST='smtp.mailtrap.io'
MAILTRAP_HOST='mailpit-smtp.mailpit.svc.cluster.local'
#MAILTRAP_PORT=2525
MAILTRAP_PORT=1025
ADMINUSER_EMAIL='admin@cp4i.demo.net'
######################
# SET APIC VARIABLES #
######################
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_MAILSERVER_NAME='dummy-mail-server'
APIC_CMC_USER='integration-admin'
APIC_USER_REGISTRY='integration-keycloak'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}" --ignore-not-found | base64 -d)
if [[ ! -z "${APIC_MGMT_SERVER}" ]]
then
   #################
   # LOGIN TO APIC #
   #################
   echo "Login to APIC with CMC Admin User..."
   apic client-creds:clear
   apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
   ##################################################
   # INITIAL APIC CONFIGURATION RIGHT AFTER INSTALL #
   # ENABLE API KEY MULTIPLE TIME USAGRE,           #
   # UPDATE EMAIL SERVER WITH MAILTRAP INFO AND     #
   # ADMIN ACCOUNT EMAIL FIELD.                     #
   ################################################## 
   echo "Enabling API Key multiple time usage..."
   apic cloud-settings:update --server $APIC_MGMT_SERVER templates/template-apic-cloud-settings.yaml
   #echo "Update session expiration time to live..."
   #apic user-registries:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG integration-keycloak templates/template-apic-user-registry-settings.yaml
   echo "Getting Mail Server Info..."
   apic mail-servers:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json $APIC_MAILSERVER_NAME
   echo "Updating Mail Server Info..."
   #jq --arg MAILTRAP_HOST $MAILTRAP_HOST \
   #    --argjson MAILTRAP_PORT $MAILTRAP_PORT \
   #    --arg MAILTRAP_USER $MAILTRAP_USER \
   #    --arg MAILTRAP_PWD $MAILTRAP_PWD \
   #     '.host=$MAILTRAP_HOST |
   #     .port=$MAILTRAP_PORT |
   #     .credentials.username=$MAILTRAP_USER |
   #     .credentials.password=$MAILTRAP_PWD | 
   #     del(.created_at, .updated_at)' \
   #    "${APIC_MAILSERVER_NAME}.json"  > "${APIC_MAILSERVER_NAME}-updated.json"
   jq --arg MAILTRAP_HOST $MAILTRAP_HOST \
      --argjson MAILTRAP_PORT $MAILTRAP_PORT \
      '.host=$MAILTRAP_HOST |
      .port=$MAILTRAP_PORT |
      del(.credentials, .created_at, .updated_at)' \
      "${APIC_MAILSERVER_NAME}.json"  > "${APIC_MAILSERVER_NAME}-updated.json"
   echo "Updating Mail Server..."
   apic mail-servers:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG $APIC_MAILSERVER_NAME "${APIC_MAILSERVER_NAME}-updated.json"
   echo "Getting CMC Admin User Info..."
   apic users:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY --format json $APIC_CMC_USER
   echo "Updating CMC Admin User eMail Info..."
   jq --arg ADMINUSER_EMAIL $ADMINUSER_EMAIL \
      '.email=$ADMINUSER_EMAIL | 
      del(.created_at, .updated_at, .last_login_at)' \
      "${APIC_CMC_USER}.json" > "${APIC_CMC_USER}-updated.json"
   echo "Updating CMC Admin User..."
   apic users:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY $APIC_CMC_USER "${APIC_CMC_USER}-updated.json"
   echo "Cleaning up temp files..."
   rm -f "${APIC_MAILSERVER_NAME}.json"
   rm -f "${APIC_MAILSERVER_NAME}-updated.json"
   rm -f "${APIC_CMC_USER}.json"
   rm -f "${APIC_CMC_USER}-updated.json"
   echo "APIC has been configured."
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi