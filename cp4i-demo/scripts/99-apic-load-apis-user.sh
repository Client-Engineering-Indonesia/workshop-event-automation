#!/bin/bash
CLIENT_ID_API1="$1"
CLIENT_ID_API2="$2"
while true; do
   clear
   echo "Invoking API..."
   random_number=$(( ( RANDOM % 6 ) + 1 ))
   case "$random_number" in
   1) curl -k --request GET \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/jgraceivt/v1/hello \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API1}" \
        --header 'accept: application/json'
      ;;
   2) curl -k --request GET \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/jgraceivt/v1/hello/ESQL \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API1}" \
        --header 'accept: application/json'
      ;;
   3) curl -k --request GET \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/jgraceivt/v1/hello/JAVA \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API1}" \
        --header 'accept: application/json'
      ;;
   4) curl -k --request GET \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/jgraceivt/v1/hello/MAP \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API1}" \
        --header 'accept: application/json'
      ;;
   5) curl -k --request GET \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/SFLeads/lead/12345 \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API2}" \
        --header 'accept: application/json'
      ;;
   6) curl -k --request POST \
        --url https://apim-demo-gw-gateway-tools.apps.67a6c0b0f9f6659c21a12181.ap1.techzone.ibm.com/cp4i-demo-org/demo/SFLeads/lead \
        --header "X-IBM-Client-Id: ${CLIENT_ID_API2}" \
        --header 'accept: application/json' \
        --header 'content-type: application/json' \
        --data '{"comments": "teom","company": "fateajkajlero","email": "hum@ruhme.gw","fname": "Max","id": "305307202879488","lname": "Grifoni","phone": "(264) 831-6045"}'
      ;;
   esac
   sleep 20
done