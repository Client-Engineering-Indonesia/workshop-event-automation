#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
echo "Configuring Catalogs..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
######################
# SET APIC VARIABLES #
######################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
APIC_CATALOG='sandbox'
APIC_PORTAL_TYPE='drupal'
CATALOG_NAME="demo"
CATALOG_TITLE="Demo"
CATALOG_SUMMARY="Demo Catalog"
APIC_AVAILABILITY_ZONE='availability-zone-default'
if [[ ! -z "${APIC_MGMT_SERVER}" ]]
then
    #################
    # LOGIN TO APIC #
    #################
    echo "Login to APIC with Provider Organization user..."
    if [ -z "$APIC_API_KEY" ]
    then
        if [ -z "$USER_NAME" ]
        then
            APIC_ORG='cp4i-demo-org'
            APIC_REALM='provider/integration-keycloak'
            echo "Login to APIC with CP4I Admin User using SSO..."
            apic login --server $APIC_MGMT_SERVER --sso --context provider
        else
            APIC_ORG='tz-provider-org'
            APIC_REALM='provider/default-idp-2'
            echo "Login to APIC with User $USER_NAME..."
            apic login --server $APIC_MGMT_SERVER --username $USER_NAME --password $USER_PWD --realm $APIC_REALM
        fi
    else
        APIC_ORG='cp4i-demo-org'
        APIC_REALM='provider/integration-keycloak'
        echo "Login to APIC with CP4I Admin User using API Key..."
        apic login --server $APIC_MGMT_SERVER --sso --context provider --apiKey $APIC_API_KEY
    fi
    if [ $? -eq 0 ]
    then
        ###########################################
        # UPDATE SANDBOX CATALOG TO ENABLE PORTAL #
        ###########################################
        echo "Getting Portal URL..."
        APIC_PORTAL_URL=$(apic portal-services:list --server $APIC_MGMT_SERVER --scope org --org $APIC_ORG | awk '{print $4}')
        #echo $APIC_PORTAL_URL
        #echo "Getting Sandbox Catalog Settings..."
        #apic catalog-settings:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --format json
        #echo "Updating Catalog Settings File..."
        #jq --arg PORTAL_URL $APIC_PORTAL_URL \
        #   --arg APIC_PORTAL_TYPE $APIC_PORTAL_TYPE \
        #   '.portal.type=$APIC_PORTAL_TYPE |
        #   .portal.portal_service_url=$PORTAL_URL |
        #   del(.created_at, .updated_at)' \
        #   catalog-setting.json > catalog-setting-sandbox.json
        #echo "Enabling Portal in Catalog Sandbox..."
        #apic catalog-settings:update --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG catalog-setting-sandbox.json
        #########################################
        # CREATE DEMO CATALOG AND ENABLE PORTAL #
        #########################################
        echo "Getting Sandbox Catalog definition..."
        apic catalogs:get --server $APIC_MGMT_SERVER --org $APIC_ORG --format json $APIC_CATALOG
        jq --arg CATALOG_NAME $CATALOG_NAME \
        --arg CATALOG_TITLE $CATALOG_TITLE \
        --arg CATALOG_SUMMARY "$CATALOG_SUMMARY" \
        '.name=$CATALOG_NAME |
        .title=$CATALOG_TITLE |
        .summary=$CATALOG_SUMMARY |
        del(.id, .created_at, .updated_at, .url)' \
        sandbox.json > demo.json
        echo "Checking if Demo Catalog already exists..."
        CATALOGS=$(apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname=$CATALOG_NAME '$1 == catname { ++count } END { print count }')
        if [ -z $CATALOGS ] 
        then 
            echo "Creating Demo Catalog..."
            CATALOG_URL=$(apic catalogs:create --server $APIC_MGMT_SERVER --org $APIC_ORG demo.json | awk '{print $2}')
        else
            echo "Demo Catalog already exists."
            CATALOG_URL=$(apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG | awk -v catname=$CATALOG_NAME '$1 == catname { print $2 }')
        fi
        echo "Getting Demo Catalog Settings..."
        #rm -f catalog-setting.json
        apic catalog-settings:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --format json
        echo "Updating Catalog Settings File..."
        jq --arg PORTAL_URL $APIC_PORTAL_URL \
        --arg APIC_PORTAL_TYPE $APIC_PORTAL_TYPE \
        '.portal.type=$APIC_PORTAL_TYPE |
        .portal.portal_service_url=$PORTAL_URL |
        .consumer_catalog_enabled=false |
        del(.created_at, .updated_at)' \
        catalog-setting.json > catalog-setting-demo.json
        echo "Enabling Portal in Catalog Demo..."
        apic catalog-settings:update --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME catalog-setting-demo.json
        #################################################
        # PUBLISH PRODUCT WITH REST API TO DEMO CATALOG #
        #################################################
        PRODLIST=$(apic products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog | awk '$1 == "jgrmqapi-product:1.2.0" { ++count } END { print count }')
        if [ -z $PRODLIST ] 
        then
            if [[ -f resources/jgrmqapi_1.2.0.yaml ]] && [[ -s resources/jgrmqapi_1.2.0.yaml ]]
            then
                echo "Publishing Product with Rest API in Demo Catalog..."
                apic products:publish --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME resources/05-jgr-mqapi-product.yaml
            else
                echo "Skipping Product publication with Rest API. API definition file is NOT available."
            fi
        else
            echo "jgrmqapi-product:1.2.0 already exists."
        fi
        if [ ! -z "$EA_WATSONX" ]
        then
            PRODLIST=$(apic products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog | awk '$1 == "watsonx-product:1.0.0" { ++count } END { print count }')
            if [ -z $PRODLIST ] 
            then
                echo "Publishing Product with WatsonX API in Demo Catalog..."
                apic products:publish --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME resources/15-watsonx-ea-product.yaml
            else
                echo "watsonx-product:1.0.0 already exists."
            fi
        fi
        ####################################
        # UPDATE CATALOGS WITH EEM GATEWAY #
        ####################################
        if [ ! -z "$EEM_APIC_INT" ]
        then
            echo "Updating Catalogs with EEM Gateway..."
            apic gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ORG --availability-zone $APIC_AVAILABILITY_ZONE --scope org --format json eem-gateway-service
            GATEWAY_SERVICE_NAME=$(jq -r '.name' "eem-gateway-service.json")
            GATEWAY_SERVICE_URL=$(jq -r '.url' "eem-gateway-service.json")
            GATEWAY_SERVICE_TYPE=$(jq -r '.gateway_service_type' "eem-gateway-service.json")
            ( echo "cat <<EOF" ; cat templates/template-apic-configured-gateway-service.yaml ;) | \
                GATEWAY_SERVICE_NAME=${GATEWAY_SERVICE_NAME} \
                GATEWAY_SERVICE_URL=${GATEWAY_SERVICE_URL} \
                GATEWAY_SERVICE_TYPE=${GATEWAY_SERVICE_TYPE} \
                sh > apic-configured-gateway-service.yaml
            echo "Catalog " $APIC_CATALOG
            EEM_GTWY_SVC=$(apic configured-gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog | awk '$1 == "eem-gateway-service" { ++count } END { print count }')
            if [ -z $EEM_GTWY_SVC ]
            then
                apic configured-gateway-services:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog apic-configured-gateway-service.yaml
            else
                echo "eem-gateway-service already created in catalog " $APIC_CATALOG
            fi
            echo "Catalog " $CATALOG_NAME
            EEM_GTWY_SVC=$(apic configured-gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog | awk '$1 == "eem-gateway-service" { ++count } END { print count }')
            if [ -z $EEM_GTWY_SVC ]
            then
                apic configured-gateway-services:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog apic-configured-gateway-service.yaml
            else
                echo "eem-gateway-service already created in catalog " $CATALOG_NAME
            fi
            #################################################
            # PUBLISH PRODUCT WITH ASYNCAPI TO DEMO CATALOG #
            #################################################
            PRODLIST=$(apic products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog | awk '$1 == "jgrasyncapi-product:1.0.0" { ++count } END { print count }')
            if [ -z $PRODLIST ] 
            then
                if [[ -f resources/cp4i-es-demo-topic.yaml ]] && [[ -s resources/cp4i-es-demo-topic.yaml ]]
                then
                    echo "Publishing Product with AsyncAPI in Demo Catalog..."
                    apic products:publish --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME resources/06-jgr-asyncapi-product.yaml
                    apic products:get --scope catalog --format json --output artifacts --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME jgrasyncapi-product:1.0.0
                else
                    echo "Skipping Product publication with AsyncAPI. API definition file is NOT available."
                fi
            else
                echo "jgrasyncapi-product:1.0.0 already exists."
            fi
        fi
        #######################################
        echo "Cleaning up temp files..." 
        rm -f catalog-setting.json
        #rm -f catalog-setting-sandbox.json
        rm -f catalog-setting-demo.json
        rm -f sandbox.json
        rm -f demo.json
        rm -f resources/jgrmqapi_1.2.0.yaml
        rm -f resources/cp4i-es-demo-topic.yaml
        rm -f artifacts/jgrasyncapi-product_1.0.0.json
        rm -f eem-gateway-service.json
        rm -f apic-configured-gateway-service.yaml
        echo "Catalogs have been configured"
    else
        echo "Couldn't login to API Connect. Check the credentials provided and try again."
    fi
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi