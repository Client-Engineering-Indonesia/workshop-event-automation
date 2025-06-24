#!/bin/sh
# This script requires the oc and jq commands to be installed in your environment
# And before running the script you need to set an environment variable call "EEM_TOKEN" with the corresponding token, i.e. using this command:
# "export EEM_TOKEN=my-eem-token"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
if [ ! -d "./templates" ]; then echo "You are not at the right place to run script. Check location and try again."; exit 1; fi;
if [ -z "$EEM_TOKEN" ]; then echo "EEM_TOKEN not set, it must be provided on the command line."; exit 1; fi;
echo "Event Endpoint Manager Configuration..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
CLEAN_CONFIG='true'
##########################
# PREPARE CONFIG CONTENT #
##########################
EEM_API=$(oc get route -n $EEM_NAMESPACE ${EEM_INST_NAME}-ibm-eem-admin -ojsonpath='https://{.spec.host}' --ignore-not-found)
if [[ ! -z "${EEM_API}" ]]
then
     ES_BOOTSTRAP_SERVER=$(oc get eventstreams ${ES_INST_NAME} -n ${ES_NAMESPACE} --ignore-not-found -o=jsonpath='{range .status.kafkaListeners[*]}{.name} {.bootstrapServers}{"\n"}{end}' 2>/dev/null | awk '$1=="authsslsvc" {print $2}')
     if [[ ! -z "${ES_BOOTSTRAP_SERVER}" ]]
     then
          ES_BOOTSTRAP_SERVER=$(echo ${ES_BOOTSTRAP_SERVER%:*})
          #ES_CERTIFICATE=$(oc get eventstreams $ES_INST_NAME -n $ES_NAMESPACE -o jsonpath='{.status.kafkaListeners[?(@.name=="authsslsvc")].certificates[0]}')
          #ES_CERTIFICATE=${ES_CERTIFICATE//$'\n'/\\\\n}
          #echo $ES_CERTIFICATE
          #printf "%s\\n" "$ES_CERTIFICATE"
          ES_PASSWORD=$(oc get secret eem-user -n $ES_NAMESPACE -ojsonpath='{.data.password}' --ignore-not-found | base64 -d)
          if [[ ! -z "${ES_PASSWORD}" ]]
          then
               oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.crt
               ES_CERTIFICATE=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ca.crt)
               ( echo "cat <<EOF" ; cat templates/template-eem-es-cluster.json ;) | \
               ES_BOOTSTRAP_SERVER=${ES_BOOTSTRAP_SERVER} \
               ES_CERTIFICATE=${ES_CERTIFICATE} \
               ES_PASSWORD=${ES_PASSWORD} \
               sh > eem-es-cluster.json
               echo "Checking if ES Cluster exists..."
               RESP_CODE=$(curl -X GET -s -k \
                    --dump-header eem-api-header \
                    -H 'Accept: application/json' \
                    -H 'Content-Type: application/json' \
                    -H "Authorization: Bearer $EEM_TOKEN" \
                    --output eem-response-data.json \
                    --write-out '%{response_code}' \
                    $EEM_API/eem/clusters)
               if [[ "${RESP_CODE}" != "200" ]]
               then
                    if [[ "${RESP_CODE}" == "401" ]]
                    then
                         echo "EEM Token is not valid. Check the value and correct it."
                    else
                         echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                         echo "Check EEM & ES are up and running and properly configured."
                    fi
                    clusterId="00000000-0000-0000-0000-000000000000"
                    CLEAN_CONFIG='false'
               else
                    clusterId=$(jq 'map(select(.name=="es-demo")) | .[] .id' eem-response-data.json)
                    if [ -z $clusterId ]
                    then
                         echo "Cluster does NOT exist."
                         echo "Creating ES Cluster reference in EEM..."
                         RESP_CODE=$(curl -X POST -s -k \
                              --dump-header eem-api-header \
                              -H 'Accept: application/json' \
                              -H 'Content-Type: application/json' \
                              -H "Authorization: Bearer $EEM_TOKEN" \
                              --data @eem-es-cluster.json \
                              --output eem-response-data.json \
                              --write-out '%{response_code}' \
                              $EEM_API/eem/clusters)
                         if [[ "${RESP_CODE}" != "200" ]]
                         then
                              echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                              echo "Check EEM & ES are up and running and properly configured."
                              clusterId="00000000-0000-0000-0000-000000000000"
                              CLEAN_CONFIG='false'
                         else
                              clusterId=$(jq .id eem-response-data.json)
                         fi
                    else
                         echo "Cluster does exist."
                         echo "ClusterID = " $clusterId
                    fi
               fi
               if [[ "${clusterId}" != "00000000-0000-0000-0000-000000000000" ]]
               then
                    #topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.ONLINE" "ORDERS.NEW" "STOCK.NOSTOCK" "SENSOR.READINGS" "STOCK.MOVEMENT" "cp4i-es-demo-topic")
                    topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.ONLINE" "ORDERS.NEW" "STOCK.NOSTOCK" "SENSOR.READINGS" "STOCK.MOVEMENT" "PRODUCT.RETURNS" "PRODUCT.REVIEWS" "cp4i-es-demo-topic")
                    for topic in "${topics[@]}"
                    do
                         echo "Checking if Topic already exists..."
                         RESP_CODE=$(curl -X GET -s -k \
                              --dump-header eem-api-header \
                              -H 'Accept: application/json' \
                              -H 'Content-Type: application/json' \
                              -H "Authorization: Bearer $EEM_TOKEN" \
                              --output eem-response-data.json \
                              --write-out '%{response_code}' \
                              $EEM_API/eem/eventsources)
                         if [[ "${RESP_CODE}" != "200" ]]
                         then
                              echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                              echo "Check EEM & ES are up and running and properly configured."
                              eventSourceId="00000000-0000-0000-0000-000000000000"
                              CLEAN_CONFIG='false'
                         else
                              topicName=$(jq -r '.topic.name'  templates/template-eem-eventsource-$topic.json)    
                              eventSourceId=$(jq --arg topicName "$topicName" 'map(select(.topic.name==$topicName)) | .[] .id' eem-response-data.json)
                              if [ -z $eventSourceId ]
                              then
                                   echo "Event Source does NOT exist"
                                   echo "Creating Topic..." $topicName
                                   RESP_CODE=$(curl -X POST -s -k \
                                        --dump-header eem-api-header \
                                        -H 'Accept: application/json' \
                                        -H 'Content-Type: application/json' \
                                        -H "Authorization: Bearer $EEM_TOKEN" \
                                        --data "$(cat templates/template-eem-eventsource-$topic.json | jq ".clusterId |= ${clusterId}")" \
                                        --output eem-response-data.json \
                                        --write-out '%{response_code}' \
                                        $EEM_API/eem/eventsources)
                                   if [[ "${RESP_CODE}" != "200" ]]
                                   then
                                        if [[ "${RESP_CODE}" == "422" ]]
                                        then
                                             echo "Most likely Topic ${topicName} is not defined in ES instance ${ES_INST_NAME}. Check and try again."
                                        else
                                             echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                                             echo "Check EEM & ES are up and running and properly configured."
                                        fi
                                        eventSourceId="00000000-0000-0000-0000-000000000000"
                                        CLEAN_CONFIG='false'
                                   else
                                        eventSourceId=$(jq .id eem-response-data.json)
                                   fi                    
                              else
                                   echo "Event Source does exist"
                                   echo "EventSourceID = " $eventSourceId
                              fi
                              if [[ "${eventSourceId}" != "00000000-0000-0000-0000-000000000000" ]]
                              then
                                   echo "Checking if Option already exists..."
                                   RESP_CODE=$(curl -X GET -s -k \
                                        --dump-header eem-api-header \
                                        -H 'Accept: application/json' \
                                        -H 'Content-Type: application/json' \
                                        -H "Authorization: Bearer $EEM_TOKEN" \
                                        --output eem-response-data.json \
                                        --write-out '%{response_code}' \
                                        $EEM_API/eem/options)
                                   if [[ "${RESP_CODE}" != "200" ]]
                                   then
                                        echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                                        echo "Check EEM & ES are up and running and properly configured."
                                        asyncapiOptionId="00000000-0000-0000-0000-000000000000"
                                        CLEAN_CONFIG='false'
                                   else
                                        optionName=$(jq -r '.alias' templates/template-eem-option-$topic.json)    
                                        asyncapiOptionId=$(jq -r --arg optionName "$optionName" 'map(select(.alias==$optionName)) | .[] .id' eem-response-data.json)                                        
                                        if [ -z $asyncapiOptionId ]
                                        then
                                             echo "Option does NOT exist"
                                             echo "Creating Option..." $optionName
                                             RESP_CODE=$(curl -X POST -s -k \
                                                  --dump-header eem-api-header \
                                                  -H 'Accept: application/json' \
                                                  -H 'Content-Type: application/json' \
                                                  -H "Authorization: Bearer $EEM_TOKEN" \
                                                  --data "$(cat templates/template-eem-option-$topic.json | jq ".eventSourceId |= ${eventSourceId}")" \
                                                  --output eem-response-data.json \
                                                  --write-out '%{response_code}' \
                                                  $EEM_API/eem/options)
                                             if [[ "${RESP_CODE}" != "200" ]]
                                             then
                                                  echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                                                  echo "Check EEM & ES are up and running and properly configured."
                                                  asyncapiOptionId="00000000-0000-0000-0000-000000000000"
                                                  CLEAN_CONFIG='false'
                                             else
                                                  asyncapiOptionId=$(jq -r .id eem-response-data.json)
                                             fi                                                  
                                        else
                                             echo "Option does exist"
                                             echo "AsyncAPIOptionID = " $asyncapiOptionId
                                        fi
                                        if [[ "${eventSourceId}" != "00000000-0000-0000-0000-000000000000" ]] && 
                                        [ ! -z $EEM_APIC_INT ]
                                        then
                                             echo "Getting AsyncAPI for APIC..."
                                             RESP_CODE=$(curl -X GET -s -k \
                                                  --dump-header eem-api-header \
                                                  -H 'Accept: application/yaml' \
                                                  -H 'Content-Type: application/json' \
                                                  -H "Authorization: Bearer $EEM_TOKEN" \
                                                  --output artifacts/$topic.yaml \
                                                  --write-out '%{response_code}' \
                                                  $EEM_API/eem/options/${asyncapiOptionId}/apicasyncapi)
                                             if [[ "${RESP_CODE}" != "200" ]]
                                             then
                                                  echo "There is a problem accessing EEM. Response code ${RESP_CODE}"
                                                  echo "Check EEM & ES are up and running and properly configured."
                                                  CLEAN_CONFIG='false'
                                             fi                                                  
                                        fi
                                   fi
                              fi
                         fi
                    done
               fi
               echo "Cleaning up temp files..."
               rm -f ca.crt
               rm -f eem-api-header
               rm -f eem-es-cluster.json
               rm -f eem-response-data.json
               if [[ "${CLEAN_CONFIG}" == "true" ]]
               then
                    echo "Event Endpoint Manager configuration has completed successfully."
               else
                    echo "Event Endpoint Manager configuration has completed with errors. Check and try again."
               fi
          else
               echo "User eem-user is not defined in ES instance ${ES_INST_NAME}. Check and try again."
          fi
     else
          echo "ES instance ${ES_INST_NAME} is not deployed in namespace ${ES_NAMESPACE}. Check and try again."
     fi
else
     echo "EEM instance ${EEM_INST_NAME} is not deployed in namespace ${EEM_NAMESPACE}. Check and try again."
fi