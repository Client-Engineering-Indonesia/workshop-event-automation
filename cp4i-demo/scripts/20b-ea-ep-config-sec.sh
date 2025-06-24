#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set a environment variables called "EP_ADMIN_PWD" using this command: 
# "export EP_ADMIN_PWD=my-eem-admin-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$EP_ADMIN_PWD" ] && [ -z "$EA_OIDC" ]; then echo "EP_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
#echo "OCP_TYPE is set to" $OCP_TYPE
if [ -z "$EA_OIDC" ]; then EP_ADMIN_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-'); fi;
read -p "Press <Enter> to execute script..."
echo "Configuring Event Processing security..."
###################
# INPUT VARIABLES #
###################
EP_INST_NAME='ep-demo'
EP_NAMESPACE='tools'
if [ -z "$EA_OIDC" ]
then
    (echo "cat <<EOF" ; cat templates/template-ep-user-credentials.json ;) | \
        EP_ADMIN_PWD=${EP_ADMIN_PWD} \
        sh > ep-user-credentials.json
    SECRET_DATA_BASE64=$(base64 -i ep-user-credentials.json | tr -d '\n')
    oc patch secret ${EP_INST_NAME}-ibm-ep-user-credentials -n $EP_NAMESPACE --patch '{"data":{"user-credentials.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    SECRET_DATA_BASE64=$(base64 -i resources/11-ep-user-roles.json | tr -d '\n')
    oc patch secret ${EP_INST_NAME}-ibm-ep-user-roles -n $EP_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    echo "Cleaning up temp files..." 
    rm -f ep-user-credentials.json
else
    SECRET_DATA_BASE64=$(base64 -i resources/11-ep-user-roles-oidc.json | tr -d '\n')
    oc patch secret ${EP_INST_NAME}-ibm-ep-user-roles -n $EP_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
fi
if [ -z "$EA_OIDC" ]
then
    echo "Password for ep-admin is:" ${EP_ADMIN_PWD}
    read -p "Write down the password and then press <Enter> to finish..."
fi
echo "Event Processing security has been configured"