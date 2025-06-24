#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set two environment variables called "EEM_ADMIN_PWD" and "ES_USER_PWD" with your maintrap info, using these command: 
# "export EEM_ADMIN_PWD=my-eem-admin-pwd"
# "export ES_USER_PWD=my-es-user-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$EEM_ADMIN_PWD" ] && [ -z "$EA_OIDC" ]; then echo "EEM_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$EEM_USER_PWD" ] && [ -z "$EA_OIDC" ]; then echo "ES_USER_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
if [ -z "$EA_OIDC" ]
then
    EEM_ADMIN_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
    EEM_USER_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
    #echo "EEM_ADMIN_PWD is set to" $EEM_ADMIN_PWD
    #echo "EEM_USER_PWD is set to" $EEM_USER_PWD
fi
read -p "Press <Enter> to execute script..."
echo "Configuring EEM Manager security..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
if [ -z "$EA_OIDC" ]
then
    echo "Configuring EEM Manager instance with local security..."
    (echo "cat <<EOF" ; cat templates/template-eem-user-credentials.json ;) | \
        EEM_ADMIN_PWD=${EEM_ADMIN_PWD} \
        EEM_USER_PWD=${EEM_USER_PWD} \
        sh > eem-user-credentials.json
    SECRET_DATA_BASE64=$(base64 -i eem-user-credentials.json | tr -d '\n')
    oc patch secret ${EEM_INST_NAME}-ibm-eem-user-credentials -n $EEM_NAMESPACE --patch '{"data":{"user-credentials.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    SECRET_DATA_BASE64=$(base64 -i resources/10-eem-user-roles.json | tr -d '\n')
    oc patch secret ${EEM_INST_NAME}-ibm-eem-user-roles -n $EEM_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
    echo "Cleaning up temp files..." 
    rm -f eem-user-credentials.json
    echo "Password for eem-admin is:" ${EEM_ADMIN_PWD}
    echo "Password for eem-user is:" ${EEM_USER_PWD}
    read -p "Write down the passwords and then press <Enter> to finish..."
else
    echo "Configuring EEM Manager instance with OIDC security..."
#    (echo "cat <<EOF" ; cat templates/template-eem-user-roles-oidc.json ;) | \
#        OIDC_SUB=${OIDC_SUB} \
#        sh > eem-user-roles-oidc.json
#    SECRET_DATA_BASE64=$(base64 -i eem-user-roles-oidc.json | tr -d '\n')
#    oc patch secret ${EEM_INST_NAME}-ibm-eem-user-roles -n $EEM_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
#    echo "Cleaning up temp files..." 
#    rm -f eem-user-roles-oidc.json
    oc patch IntegrationKeycloakClient eem-demo-mgr-ibm-eem-keycloak -n tools --patch '{"spec":{"client":{"optionalClientScopes":["offline_access"]}}}' --type=merge
fi
echo "EEM Manager security has been configured"