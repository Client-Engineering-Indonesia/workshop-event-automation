#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
echo "Creating Apps and Subscription..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
######################
# SET APIC VARIABLES #
######################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
CATALOG_NAME="demo"
CONSUMER_ORG_NAME='AppDevOrg'
if [[ ! -z "${APIC_MGMT_SERVER}" ]]
then
    #################
    # LOGIN TO APIC #
    #################
    echo "Login to APIC with CMC Admin User..."
    APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
    apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
    echo "Setting APIC variables..."
    if [ -z "$USER_NAME" ]
    then
        APIC_ORG='cp4i-demo-org'
        APIC_REALM='provider/integration-keycloak'  
    else
        APIC_ORG='tz-provider-org'
        APIC_REALM='provider/default-idp-2'
    fi
    echo "Getting Provider Organization URL..."      
    PORG_URL=$(apic orgs:list --server $APIC_MGMT_SERVER | awk -v porgname="${APIC_ORG}" '$1 == porgname {print $4}')
    echo "Login to APIC with Provider Organization user..."
    if [ -z "$APIC_API_KEY" ]
    then
        if [ -z "$USER_NAME" ]
        then
            echo "Login to APIC with CP4I Admin User using SSO..."
            apic login --server $APIC_MGMT_SERVER --sso --context provider
        else
            echo "Login to APIC with User $USER_NAME..."
            apic login --server $APIC_MGMT_SERVER --username $USER_NAME --password $USER_PWD --realm $APIC_REALM
        fi
    else
        echo "Login to APIC with CP4I Admin User using API Key..."
        apic login --server $APIC_MGMT_SERVER --sso --context provider --apiKey $APIC_API_KEY
    fi
    if [ $? -eq 0 ]
    then
        CATALOG_URL=$(apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname="${CATALOG_NAME}" '$1 == catname {print $2}')
        CONSUMER_ORG_URL=$(apic consumer-orgs:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME | awk -v corgname="${CONSUMER_ORG_NAME}" '$1 == corgname {print $4}')
        PRODUCT_URL=$(apic products:list --scope catalog --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME jgrasyncapi-product | awk '{print $4}')
        ##############################################
        # CREATE APP IN CONSUMER ORG IN DEMO CATALOG #
        ##############################################
        echo "Preparing App File"
        # Demo App
        APP_NAME='CP4I-Demo-App'
        ( echo "cat <<EOF" ; cat templates/template-apic-app.json ;) | \
            APP_NAME=${APP_NAME} \
            APP_TITLE='CP4I Demo App' \
            PORG_URL=${PORG_URL} \
            CATALOG_URL=${CATALOG_URL} \
            CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
            sh > demo-app.json
        APPS_LIST=$(apic apps:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME | awk -v appname=$APP_NAME '$1 == appname { ++count } END { print count }')
        if [ -z $APPS_LIST ]
        then
            echo "Creating Demo App for Consumer Org in Catalog Demo..."
            rm -f artifacts/CP4I-Demo-App.json
            apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME demo-app.json
        else
            echo "Demo App for Consumer Org in Catalog Demo already exists."
        fi
        APP_URL=$(jq -r '.url' "artifacts/CP4I-Demo-App.json")
        # Dflt App
        ( echo "cat <<EOF" ; cat templates/template-apic-app.json ;) | \
            APP_NAME='CP4I-Dflt-App' \
            APP_TITLE='CP4I Dflt App' \
            PORG_URL=${PORG_URL} \
            CATALOG_URL=${CATALOG_URL} \
            CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
            sh > dflt-app.json
        APPS_LIST=$(apic apps:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME | awk '$1 == "CP4I-Dflt-App" { ++count } END { print count }')
        if [ -z $APPS_LIST ]
        then
            echo "Creating Dflt App for Consumer Org in Catalog Demo..."
            rm -f artifacts/CP4I-Dflt-App.json
            apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME dflt-app.json
        else
            echo "Dflt App for Consumer Org in Catalog Demo already exists."
        fi
        # Prem App
        ( echo "cat <<EOF" ; cat templates/template-apic-app.json ;) | \
            APP_NAME='CP4I-Prem-App' \
            APP_TITLE='CP4I Prem App' \
            PORG_URL=${PORG_URL} \
            CATALOG_URL=${CATALOG_URL} \
            CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
            sh > prem-app.json
        APPS_LIST=$(apic apps:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME | awk '$1 == "CP4I-Prem-App" { ++count } END { print count }')
        if [ -z $APPS_LIST ]
        then
            echo "Creating Prem App for Consumer Org in Catalog Demo..."
            rm -f artifacts/CP4I-Prem-App.json
            apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME prem-app.json
        else
            echo "Prem App for Consumer Org in Catalog Demo already exists."
        fi
        #############################################
        # CREATE SUSCRIPTION TO ASYNC PROD FROM APP #
        #############################################
        if [ ! -z "$EEM_APIC_INT" ]
        then
            echo "Preparing Subscription File"
            SUBSCRIPTION_NAME=$(uuidgen | awk '{print tolower($0)}') 
            ( echo "cat <<EOF" ; cat templates/template-apic-subscription.json ;) | \
                PLAN_NAME='default-plan' \
                PLAN_TITLE='Default Plan' \
                SUBSCRIPTION_NAME=${SUBSCRIPTION_NAME} \
                PRODUCT_URL=${PRODUCT_URL} \
                PORG_URL=${PORG_URL} \
                CATALOG_URL=${CATALOG_URL} \
                CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
                APP_URL=${APP_URL} \
                sh > subscription.json
            SUBS_LIST=$(apic subscriptions:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME --app $APP_NAME | awk '{ ++count } END { print count }')
            if [ -z $APPS_LIST ]
            then
                echo "Creating Subscription for Default Plan in AsyncAPI..."
                apic subscriptions:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME --app $APP_NAME subscription.json
            else
                echo "Subscription for Default Plan in AsyncAPI already exists."
            fi
        fi
        #######################################
        echo "Cleaning up temp files..." 
        rm -f demo-app.json
        rm -f dflt-app.json
        rm -f prem-app.json
        rm -f subscription.json
        echo "Apps and Subscription have been created."
    else
        echo "Couldn't login to API Connect. Check the credentials provided and try again."
    fi
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi