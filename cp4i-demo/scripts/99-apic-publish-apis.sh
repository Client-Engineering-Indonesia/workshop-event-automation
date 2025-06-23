#!/bin/sh
# This script requires the oc command being installed in your environment
# And before running the script you need to set an environment variable call "APPDEV_PWD" with the user password, i.e. using this command: "export APPDEV_PWD=my-pwd"
echo "Publising APIs, Enabling Portal in Sandbox Catalog and Creating Catalog Demo with Portal enabled..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
APIC_ORG='cp4i-demo-org'
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
ES_USER_ID='ace-user'
######################
# SET APIC VARIABLES #
######################
APIC_CATALOG='sandbox'
APIC_PORTAL_TYPE='drupal'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
CATALOG_NAME="demo"
CATALOG_TITLE="Demo"
CATALOG_SUMMARY="Demo Catalog"
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.type} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
#oc extract secret/${ES_USER_ID} -n ${ES_NAMESPACE} --keys=password
#ES_USER_PWD=`cat password`
ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.crt
ES_CA_CERT_PEM=`awk '{print "            "$0}' ca.crt`
GUUID=$(uuidgen | awk '{print tolower($0)}') 
#################
# LOGIN TO APIC #
#################
echo "Login to APIC with CP4I Admin User using SSO..."
apic login --server $APIC_MGMT_SERVER --sso --context provider
##########################################
# PUBLISH NEW APIS AND PRODUCTS TO DRAFT #
##########################################
echo "Getting Values to Publish API..."
TARGET_URL=$(oc get integrationserver jgr-designer-sfleads -n tools -o jsonpath='{.status.endpoints[0].uri}')'/SFLeads/lead'
PREMIUM_URL=$(oc get integrationserver jgr-mqapi-prem -n tools -o jsonpath='{.status.endpoints[0].uri}')
DEFAULT_URL=$(oc get integrationserver jgr-mqapi-dflt -n tools -o jsonpath='{.status.endpoints[0].uri}')
echo "Preparing API Files..."
# REST API
( echo "cat <<EOF" ; cat templates/template-apic-api-def-jgrmqapiv2.yaml ;) | \
    TARGET_URL=${TARGET_URL} \
    PREMIUM_URL=${PREMIUM_URL} \
    DEFAULT_URL=${DEFAULT_URL} \
    MSG_BODY_VAL='$(message.body)' \
    INVOKE_URL_VAL1='$(target-url)' \
    INVOKE_URL_VAL2='$(default-url)$(my-path)' \
    INVOKE_URL_VAL3='$(premium-url)$(my-path)' \
    ref='$ref' \
    sh > resources/jgrmqapi_1.2.0.yaml
# AsyncAPI
( echo "cat <<EOF" ; cat templates/template-apic-api-def-asyncapi.yaml ;) | \
    ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
    ES_USER_ID=${ES_USER_ID} \
    ES_USER_PWD=${ES_USER_PWD} \
    ES_CA_CERT_PEM=${ES_CA_CERT_PEM} \
    GUUID=${GUUID} \
    BOOTSTRAP_VAL='$(bootstrapServerAddress)' \
    sh > resources/jgrasyncapi_1.0.0.yaml
echo "Publishing APIs and Products in Draft mode..."
apic draft-products:create --server $APIC_MGMT_SERVER --org $APIC_ORG resources/05-jgr-mqapi-product.yaml
apic draft-products:create --server $APIC_MGMT_SERVER --org $APIC_ORG resources/06-jgr-asyncapi-product.yaml
apic draft-apis:get --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG jgrasyncapi:1.0.0
###########################################
# UPDATE SANDBOX CATALOG TO ENABLE PORTAL #
###########################################
echo "Getting Portal URL..."
APIC_PORTAL_URL=$(apic portal-services:list --server $APIC_MGMT_SERVER --scope org --org $APIC_ORG | awk '{print $4}')
echo $APIC_PORTAL_URL
echo "Getting Sandbox Catalog Settings..."
apic catalog-settings:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --format json
echo "Updating Catalog Settings File..."
jq --arg PORTAL_URL $APIC_PORTAL_URL \
   --arg APIC_PORTAL_TYPE $APIC_PORTAL_TYPE \
   '.portal.type=$APIC_PORTAL_TYPE |
   .portal.portal_service_url=$PORTAL_URL |
   del(.created_at, .updated_at)' \
   catalog-setting.json > catalog-setting-sandbox.json
echo "Enabling Portal in Catalog Sandbox..."
apic catalog-settings:update --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG catalog-setting-sandbox.json
#########################################
# CREATE DEMO CATALOG AND ENABLE PORTAL #
#########################################
apic catalogs:get --server $APIC_MGMT_SERVER --org $APIC_ORG --format json $APIC_CATALOG
jq --arg CATALOG_NAME $CATALOG_NAME \
   --arg CATALOG_TITLE $CATALOG_TITLE \
   --arg CATALOG_SUMMARY "$CATALOG_SUMMARY" \
   '.name=$CATALOG_NAME |
   .title=$CATALOG_TITLE |
   .summary=$CATALOG_SUMMARY |
   del(.id, .created_at, .updated_at, .url)' \
   sandbox.json > demo.json
echo "Creating Demo Catalog..."
CATALOG_URL=$(apic catalogs:create --server $APIC_MGMT_SERVER --org $APIC_ORG demo.json | awk '{print $2}')
echo "Getting Demo Catalog Settings..."
rm -f catalog-setting.json
apic catalog-settings:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --format json
echo "Updating Catalog Settings File..."
jq --arg PORTAL_URL $APIC_PORTAL_URL \
   --arg APIC_PORTAL_TYPE $APIC_PORTAL_TYPE \
   '.portal.type=$APIC_PORTAL_TYPE |
   .portal.portal_service_url=$PORTAL_URL |
   del(.created_at, .updated_at)' \
   catalog-setting.json > catalog-setting-demo.json
echo "Enabling Portal in Catalog Demo..."
apic catalog-settings:update --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME catalog-setting-demo.json
####################################
# PUBLISH PRODUCTS TO DEMO CATALOG #
####################################
echo "Publishing Products in Demo Catalog..."
apic products:publish --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME resources/05-jgr-mqapi-product.yaml
PRODUCT_URL=$(apic products:publish --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME resources/06-jgr-asyncapi-product.yaml | awk '{print $4}')
#######################################
# CREATE CONSUMER ORG IN DEMO CATALOG #
#######################################
CONSUMER_ORG_NAME='AppDevOrg'
PORG_URL=$(jq -r '.org_url' "catalog-setting-demo.json")
USER_REGISTRY_URL=$(apic user-registries:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname="${CATALOG_NAME}-catalog" '$1 == catname {print $2}')
echo "Preparing Consumer Org User File"
( echo "cat <<EOF" ; cat templates/template-apic-consumer-org-user.json ;) | \
    CATALOG_NAME=${CATALOG_NAME} \
    APPDEV_PWD=${APPDEV_PWD} \
    PORG_URL=${PORG_URL} \
    USER_REGISTRY_URL=${USER_REGISTRY_URL} \
sh > consumer-org-user.json
echo "Creating Consumer Org User"
OWNER_URL=$(apic users:create --server $APIC_MGMT_SERVER --org $APIC_ORG --user-registry ${CATALOG_NAME}-catalog consumer-org-user.json | awk '{print $4}')
echo "Preparing Consumer Org File"
( echo "cat <<EOF" ; cat templates/template-apic-consumer-org.json ;) | \
    ORG_NAME=${CONSUMER_ORG_NAME} \
    OWNER_URL=${OWNER_URL} \
    PORG_URL=${PORG_URL} \
    CATALOG_URL=${CATALOG_URL} \
    sh > consumer-org.json
echo "Creating Consumer Org..."
CONSUMER_ORG_URL=$(apic consumer-orgs:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME consumer-org.json | awk '{print $4}')
##############################################
# CREATE APP IN CONSUMER ORG IN DEMO CATALOG #
##############################################
echo "Preparing App File"
APP_NAME='CP4I-Demo-App'
# Demo App
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
    sh > subscription.json
echo "Creating Subscription for Default Plan in AsyncAPI..."
apic subscriptions:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG --app $APP_NAME subscription.json
#######################################
echo "Cleaning up temp files..." 
rm -f resources/jgrmqapi_1.2.0.yaml
rm -f resources/jgrasyncapi_1.0.0.yaml
rm -f catalog-setting.json
rm -f catalog-setting-sandbox.json
rm -f catalog-setting-demo.json
rm -f sandbox.json
rm -f demo.json
rm -f consumer-org-user.json
rm -f consumer-org.json
rm -f demo-app.json
rm -f dflt-app.json
rm -f prem-app.json
rm -f subscription.json
#rm -f password
rm -f ca.crt
echo "APIs have been published and Portal enabled"    