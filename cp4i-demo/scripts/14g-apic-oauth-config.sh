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
APIC_ORG='cp4i-demo-org'
######################
# SET APIC VARIABLES #
######################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
#CATALOG_NAME="demo"
#CONSUMER_ORG_NAME='AppDevOrg'
#################
# LOGIN TO APIC #
#################
echo "Login to APIC with CP4I Admin User using SSO..."
apic login --server $APIC_MGMT_SERVER --sso --context provider
PORG_URL=$(apic orgs:list --server $APIC_MGMT_SERVER | awk -v porgname="${APIC_ORG}" '$1 == porgname {print $4}')
AUTH_INT_URL=$(apic integrations:list --subcollection user-registry --server $APIC_MGMT_SERVER | awk '$1 == "authurl" {print $4}')
exit
PORG_URL=$(apic orgs:list --server $APIC_MGMT_SERVER | awk -v porgname="${APIC_ORG}" '$1 == porgname {print $4}')
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
echo "Creating Demo App for Consumer Org in Catalog Demo..."
apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME demo-app.json
APP_URL=$(jq -r '.url' "artifacts/CP4I-Demo-App.json")
# Dflt App
( echo "cat <<EOF" ; cat templates/template-apic-app.json ;) | \
    APP_NAME='CP4I-Dflt-App' \
    APP_TITLE='CP4I Dflt App' \
    PORG_URL=${PORG_URL} \
    CATALOG_URL=${CATALOG_URL} \
    CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
    sh > dflt-app.json
echo "Creating Dflt App for Consumer Org in Catalog Demo..."
apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME dflt-app.json
# Prem App
( echo "cat <<EOF" ; cat templates/template-apic-app.json ;) | \
    APP_NAME='CP4I-Prem-App' \
    APP_TITLE='CP4I Prem App' \
    PORG_URL=${PORG_URL} \
    CATALOG_URL=${CATALOG_URL} \
    CONSUMER_ORG_URL=${CONSUMER_ORG_URL} \
    sh > prem-app.json
echo "Creating Prem App for Consumer Org in Catalog Demo..."
apic apps:create --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME prem-app.json
#############################################
# CREATE SUSCRIPTION TO ASYNC PROD FROM APP #
#############################################
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
echo "Creating Subscription for Default Plan in AsyncAPI..."
apic subscriptions:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME --app $APP_NAME subscription.json
#######################################
echo "Cleaning up temp files..." 
rm -f demo-app.json
rm -f dflt-app.json
rm -f prem-app.json
rm -f subscription.json
echo "Apps and Subscription have been created."    