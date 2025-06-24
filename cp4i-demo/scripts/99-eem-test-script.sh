#!/bin/sh
# This script requires the oc and jq commands to be installed in your environment
# And before running the script you need to set an environment variable call "EEM_TOKEN" with the corresponding token, i.e. using this command:
# "export EEM_TOKEN=my-eem-token"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo "jq could not be found"; exit 1; fi;
if [ -z "$EEM_TOKEN" ]; then echo "EEM_TOKEN not set, it must be provided on the command line."; exit 1; fi;
echo "Event Endpoint Manager Configuration..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
##########################
# PREPARE CONFIG CONTENT #
##########################
EEM_API=$(oc get route -n $EEM_NAMESPACE ${EEM_INST_NAME}-ibm-eem-admin -ojsonpath='https://{.spec.host}')
echo $EEM_API

     curl -X GET -s -k \
          --dump-header eem-api-header \
          -H 'Accept: application/json' \
          -H 'Content-Type: application/json' \
          -H "Authorization: Bearer $EEM_TOKEN" \
          --output eem-response-data.json \
          --write-out '%{response_code}' \
          $EEM_API/eem/clusters

#jq '.[] | select (.name | contains("es-demo"))' eem-response-data.json
clusterId=$(jq 'map(select(.name | contains("es-demo"))) | .[] .id' eem-response-data.json)
if [ -z $clusterId ]
then
     echo "Cluster does NOT exist"
else
     echo "Cluster does exist"
fi

     curl -X GET -s -k \
          --dump-header eem-api-header \
          -H 'Accept: application/json' \
          -H 'Content-Type: application/json' \
          -H "Authorization: Bearer $EEM_TOKEN" \
          --output eem-response-data.json \
          --write-out '%{response_code}' \
          $EEM_API/eem/eventsources

#eventSourceId=$(jq 'map(select(.topic.name | contains("CANCELLATIONS"))) | .[] .id' eem-response-data.json)
topicName="CANCELLATIONS.AVRO"
eventSourceId=$(jq --arg topicName "$topicName" 'map(select(.topic.name==$topicName)) | .[] .id' eem-response-data.json)
if [ -z $eventSourceId ]
then
     echo "Event Source does NOT exist"
else
     echo "Event Source does exist"
fi

     curl -X GET -s -k \
          --dump-header eem-api-header \
          -H 'Accept: application/json' \
          -H 'Content-Type: application/json' \
          -H "Authorization: Bearer $EEM_TOKEN" \
          --output eem-response-data.json \
          --write-out '%{response_code}' \
          $EEM_API/eem/options

asyncapiOptionId=$(jq -r 'map(select(.alias=="CANCELS")) | .[] .id' eem-response-data.json)
echo $asyncapiOptionId
#jq 'map(select(.alias=="CANCELS")) | .[] .id' eem-response-data.json

     echo "Getting AsyncAPI for APIC..."
     curl -X GET -s -k \
          --dump-header eem-api-header \
          -H 'Accept: application/yaml' \
          -H 'Content-Type: application/json' \
          -H "Authorization: Bearer $EEM_TOKEN" \
          --output asyncAPI.yaml \
          --write-out '%{response_code}' \
          $EEM_API/eem/options/${asyncapiOptionId}/apicasyncapi

exit

topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.NEW" "SENSOR.READINGS" "STOCK.MOVEMENT" "cp4i-es-demo-topic")
for topic in "${topics[@]}"
do
    curl -X POST -s -k \
         --dump-header eem-api-header \
         -H 'Accept: application/json' \
         -H 'Content-Type: application/json' \
         -H "Authorization: Bearer $EEM_TOKEN" \
         --data "$(cat resources/10-eem-eventsource-$topic.json | jq ".clusterId |= ${clusterId}")" \
         --output eem-response-data.json \
         --write-out '%{response_code}' \
         $EEM_API/eem/eventsources
    eventSourceId=$(jq .id eem-response-data.json)

    curl -X POST -s -k \
         --dump-header eem-api-header \
         -H 'Accept: application/json' \
         -H 'Content-Type: application/json' \
         -H "Authorization: Bearer $EEM_TOKEN" \
         --data "$(cat resources/10-eem-option-$topic.json | jq ".eventSourceId |= ${eventSourceId}")" \
         --output /dev/null \
         --write-out '%{response_code}' \
         $EEM_API/eem/options
done
echo "Cleaning up temp files..."
rm -f ca.crt
rm -f eem-api-header
rm -f eem-es-cluster.json
rm -f eem-response-data.json
echo "Event Endpoint Manager has been configured."