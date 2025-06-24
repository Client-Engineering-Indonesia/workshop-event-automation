#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
# And before running the script you need to set an environment variable call "APPDEV_PWD" with the user password, i.e. using this command: "export APPDEV_PWD=my-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
#if [ -z "$APPDEV_PWD" ]; then echo "APPDEV_PWD not set, it must be provided on the command line."; exit 1; fi;
#echo "APPDEV_PWD is set to" $APPDEV_PWD
#read -p "Press <Enter> to execute script..."
APPDEV_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
echo "Creating Consumer Organization..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
######################
# SET APIC VARIABLES #
######################
APIC_ORG='cp4i-demo-org'
CATALOG_NAME="demo"
CONSUMER_ORG_NAME='AppDevOrg'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
if [[ ! -z "${APIC_MGMT_SERVER}" ]]
then
    #################
    # LOGIN TO APIC #
    #################
    if [ -z "$APIC_API_KEY" ]
    then
        echo "Login to APIC with CP4I Admin User using SSO..."
        apic login --server $APIC_MGMT_SERVER --sso --context provider
    else
        echo "Login to APIC with CP4I Admin User using API Key..."
        apic login --server $APIC_MGMT_SERVER --sso --context provider --apiKey $APIC_API_KEY
    fi
    if [ $? -eq 0 ]
    then
        PORG_URL=$(apic orgs:list --server $APIC_MGMT_SERVER | awk -v porgname="${APIC_ORG}" '$1 == porgname {print $4}')
        USER_REGISTRY_URL=$(apic user-registries:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname="${CATALOG_NAME}-catalog" '$1 == catname {print $2}')
        CATALOG_URL=$(apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname="${CATALOG_NAME}" '$1 == catname {print $2}')
        #######################################
        # CREATE CONSUMER ORG IN DEMO CATALOG #
        #######################################
        echo "Preparing Consumer Org User File"
        ( echo "cat <<EOF" ; cat templates/template-apic-consumer-org-user.json ;) | \
            CATALOG_NAME=${CATALOG_NAME} \
            APPDEV_PWD=${APPDEV_PWD} \
            PORG_URL=${PORG_URL} \
            USER_REGISTRY_URL=${USER_REGISTRY_URL} \
            sh > consumer-org-user.json
        CORG_USER=$(apic users:list --server $APIC_MGMT_SERVER --org $APIC_ORG --user-registry ${CATALOG_NAME}-catalog | awk '$1 == "andre" { ++count } END { print count }')
        if [ -z $CORG_USER ]
        then
            echo "Creating Consumer Org User..."
            OWNER_URL=$(apic users:create --server $APIC_MGMT_SERVER --org $APIC_ORG --user-registry ${CATALOG_NAME}-catalog consumer-org-user.json | awk '{print $4}')
        else
            echo "Consumer Org User andre already exists."
            OWNER_URL=$(apic users:list --server $APIC_MGMT_SERVER --org $APIC_ORG --user-registry ${CATALOG_NAME}-catalog | awk '$1 == "andre" {print $4}')
        fi 
        echo "Preparing Consumer Org File"
        ( echo "cat <<EOF" ; cat templates/template-apic-consumer-org.json ;) | \
            ORG_NAME=${CONSUMER_ORG_NAME} \
            OWNER_URL=${OWNER_URL} \
            PORG_URL=${PORG_URL} \
            CATALOG_URL=${CATALOG_URL} \
            sh > consumer-org.json
        CORG_LIST=$(apic consumer-orgs:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME | awk -v conorgname=$CONSUMER_ORG_NAME '$1 == conorgname { ++count } END { print count }')
        if [ -z $CORG_LIST ]
        then
            echo "Creating Consumer Org..."
            apic consumer-orgs:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME consumer-org.json
        else
            echo "Consumer Org AppDevOrg already exists."
        fi
        #######################################
        echo "Cleaning up temp files..." 
        rm -f consumer-org-user.json
        rm -f consumer-org.json
        echo "Password for App Developer is:" ${APPDEV_PWD}
        read -p "Write down the password and then press <Enter> to finish..."
        export APPDEV_PWD
        echo "Consumer Organization has been created."
    else
        echo "Couldn't login to API Connect. Check the credentials provided and try again."
    fi
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi