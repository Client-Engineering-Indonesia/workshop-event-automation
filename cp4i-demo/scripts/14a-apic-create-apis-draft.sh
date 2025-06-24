#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
read -p "Press <Enter> to execute script..."
echo "Publising APIs in Draft mode..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
ES_USER_ID='ace-user'
######################
# SET APIC VARIABLES #
######################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.type} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
#ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' | awk '$1=="external" {print $2}')
#oc extract secret/${ES_USER_ID} -n ${ES_NAMESPACE} --keys=password
#ES_USER_PWD=`cat password`
#ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
#oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.crt
#ES_CA_CERT_PEM=`awk '{print "            "$0}' ca.crt`
#GUUID=$(uuidgen | awk '{print tolower($0)}') 
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
        ##########################################
        # PUBLISH NEW APIS AND PRODUCTS TO DRAFT #
        ##########################################
        # REST API
        echo "Getting Values to Publish REST API..."
        case "$CP4I_VER" in
            "2022.2")
                TARGET_URL=$(oc get integrationserver jgr-designer-sfleads -n tools -o jsonpath='{.status.endpoints[0].uri}')'/SFLeads/lead'
                PREMIUM_URL=$(oc get integrationserver jgr-mqapi-prem -n tools -o jsonpath='{.status.endpoints[0].uri}')
                DEFAULT_URL=$(oc get integrationserver jgr-mqapi-dflt -n tools -o jsonpath='{.status.endpoints[0].uri}')
                ;;
            "2022.4" | "2023.2" | "2023.4" | "16.1.0" | "16.1.1")
                TARGET_URL=$(oc get integrationruntime jgr-designer-sfleads -n tools -o jsonpath='{.status.endpoints[0].uri}')'/SFLeads/lead'
                PREMIUM_URL=$(oc get integrationruntime jgr-mqapi-prem -n tools -o jsonpath='{.status.endpoints[0].uri}')
                DEFAULT_URL=$(oc get integrationruntime jgr-mqapi-dflt -n tools -o jsonpath='{.status.endpoints[0].uri}')
                ;;
        esac
        if [[ ! -z ${TARGET_URL} ]] && [[ ! -z ${PREMIUM_URL} ]] && [[ ! -z ${DEFAULT_URL} ]]
        then
            echo "Preparing REST API File..."
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
            echo "Publishing RES API and Product in Draft mode..."
            DPROD=$(apic draft-products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG | awk '$1 == "jgrmqapi-product:1.2.0" { ++count } END { print count }')
            if [ -z $DPROD ] 
            then 
                apic draft-products:create --server $APIC_MGMT_SERVER --org $APIC_ORG resources/05-jgr-mqapi-product.yaml
            else
                echo "jgrmqapi-product:1.2.0 already exists."
            fi
        else
            echo "Skipping REST API. Endpoints are NOT available."
        fi 
        # AsyncAPI
        if [ ! -z "$EEM_APIC_INT" ]
        then
            if [[ -f artifacts/cp4i-es-demo-topic.yaml ]] && [[ -s artifacts/cp4i-es-demo-topic.yaml ]]
            then
                cp artifacts/cp4i-es-demo-topic.yaml resources/
                echo "Publishing AsyncAPI and Product in Draft mode..."
                DPROD=$(apic draft-products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG | awk '$1 == "jgrasyncapi-product:1.0.0" { ++count } END { print count }')
                if [ -z $DPROD ] 
                then 
                    apic draft-products:create --server $APIC_MGMT_SERVER --org $APIC_ORG resources/06-jgr-asyncapi-product.yaml
                else
                    echo "jgrasyncapi-product:1.0.0 already exists."
                fi
            else
                echo "Skipping AsyncAPI. Definition file is NOT available."
            fi
        fi
        # WatsonX API
        if [ ! -z "$EA_WATSONX" ]
        then
            echo "Publishing WatsonX API and Product in Draft mode..."
            DPROD=$(apic draft-products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG | awk '$1 == "watsonx-product:1.0.0" { ++count } END { print count }')
            if [ -z $DPROD ] 
            then 
                apic draft-products:create --server $APIC_MGMT_SERVER --org $APIC_ORG resources/15-watsonx-ea-product.yaml
            else
                echo "watsonx-product:1.0.0 already exists."
            fi
        fi
        #######################################
        echo "Cleaning up temp files..." 
        #rm -f password
        #rm -f ca.crt
        echo "APIs have been published to Drafts" 
    else
        echo "Couldn't login to API Connect. Check the credentials provided and try again."
    fi
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi