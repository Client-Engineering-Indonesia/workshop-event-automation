#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
if [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.1"; exit 1; fi;
echo "Creating Engagement Destination and Rule ..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
APIC_ORG='cp4i-demo-org'
######################
# SET APIC VARIABLES #
######################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}" --ignore-not-found)
APIC_ANALYTICS_SERVICE='analytics-service'
DESTINATION_NAME="JGR ACE Destination"
RULE_NAME="JGR Demo Rule"
ACE_INST_NAME='jgr-apic-engagement'
ACE_NAMESPACE='tools'
API_PATH='/jgr-apic-engagement/message'
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
        DESTINATION_URL=$(oc get integrationruntime $ACE_INST_NAME -n $ACE_NAMESPACE --ignore-not-found -o jsonpath='{.status.endpoints[?(@.name=="http endpoint")].uri}')$API_PATH
        if [ $DESTINATION_URL != $API_PATH ]
        then
            ###################################################
            # CREATE ENGAGEMENT DESTINATION ORGANIZATION WIDE #
            ###################################################
            apic -m engagement destinations:orgList --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format json --output .
            APIC_ENG_DEST_ID=$(jq -r --arg DESTINATION_NAME "$DESTINATION_NAME" '.destinations[] | select(.title==$DESTINATION_NAME) | .id' DestinationsListResponse.json)
            if [ -z "$APIC_ENG_DEST_ID" ]
            then
                echo "Preparing Destination File..."
                ( echo "cat <<EOF" ; cat templates/template-apic-engagement-destination.yaml ;) | \
                    DESTINATION_URL=${DESTINATION_URL} \
                    sh > apic-engagement-destination.yaml
                echo "Creating Destination..." 
                apic -m engagement destinations:orgCreate --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE apic-engagement-destination.yaml
            else
                echo "APIC Engagement Destination already exists."
            fi
            rm -f DestinationsListResponse.json
            ############################################
            # CREATE ENGAGEMENT RULE ORGANIZATION WIDE #
            ############################################
            apic -m engagement rules:orgList --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format json --output .
            APIC_ENG_RULE_ID=$(jq -r --arg RULE_NAME "$RULE_NAME" '.rules[] | select(.title==$RULE_NAME) | .id' RulesListResponse.json)
            if [ -z "$APIC_ENG_RULE_ID" ]
            then
                i=0
                DESTINATION_ID=""
                while [ -z "$DESTINATION_ID" ] && [ $i -lt 5 ]
                do
                    echo "Sleeping for thirty seconds..."
                    sleep 30
                    echo "Checking if destination is ready... " $i
                    apic -m engagement destinations:orgList --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format json --output .
                    DESTINATION_ID=$(jq -r --arg DESTINATION_NAME "$DESTINATION_NAME" '.destinations[] | select(.title==$DESTINATION_NAME) | .id' DestinationsListResponse.json)
                    rm -f DestinationsListResponse.json
                    let "i++"
                done
                echo "Preparing Rule File..."
                ( echo "cat <<EOF" ; cat templates/template-apic-engagement-rule.yaml ;) | \
                    DESTINATION_ID=${DESTINATION_ID} \
                    sh > apic-engagement-rule.yaml
                echo "Creating Rule..."
                apic -m engagement rules:orgCreate --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE apic-engagement-rule.yaml
            else
                echo "APIC Engagement Rule already exists."
            fi
            #######################################
            echo "Cleaning up temp files..." 
            rm -f apic-engagement-destination.yaml
            rm -f RulesListResponse.json
            rm -f apic-engagement-rule.yaml
            echo "Destination and Rule have been created."
        else
            echo "ACE Integration ${ACE_INST_NAME} is not deployed in namespace ${ACE_NAMESPACE}. Check and try again."
        fi
    else
        echo "Couldn't login to API Connect. Check the credentials provided and try again."
    fi
else
    echo "APIC instance ${APIC_INST_NAME} is not deployed in namespace ${APIC_NAMESPACE}. Check and try again."
fi