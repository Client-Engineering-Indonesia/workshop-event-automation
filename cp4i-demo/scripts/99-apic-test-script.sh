#!/bin/sh
#!/bin/sh
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Script to test the APIC cli."
   echo "This script requires the oc command being installed in your environment"
   echo "This script requires the apic command being installed in your environment"
   echo "And before running the script you need to set the following environment variables:"
   echo "USER_NAME, USER_EMAIL, USER_FNAME, USER_LNAME, USER_PWD, PORG_NAME, and PORG_TITLE"
   echo "using the "export" command."
   echo
   echo "Syntax: 99-apic-test-script [-h|i|n|m|k|u]"
   echo "options:"
   echo "h     Print this Help."
   echo "i     Provide Instance name."
   echo "n     Provide Namespace value."
   echo "m     Type of api to test (admin|porg)"
   echo "k     Provide API Key for POrg mode"
   echo "u     Provide User Name for POrg mode"
   echo
}

ValidatePreReqs()
{
   if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
   if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
}

AdminMode()
{
   ########################
   # ADMIN APIC VARIABLES #
   ########################
   local APIC_ADMIN_USER='admin'
   local APIC_REALM='admin/default-idp-1'
   local APIC_ADMIN_ORG='admin'
   #local APIC_USER_REGISTRY='api-manager-lur'
   local APIC_USER_REGISTRY='integration-keycloak'
   local APIC_AVAILABILITY_ZONE='availability-zone-default'
   local APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
   #################################
   # LOGIN TO APIC WITH ADMIN USER #
   #################################
   echo "Login to APIC with CMC admin user ..."
   apic client-creds:clear
   apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
   ################################
   # TEST APIC CLI FOR ADMIN ROLE #
   ################################
   #apic keystores:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG apim-demo-keystore
   #apic keystores:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic truststores:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG apim-demo-truststore
   #apic truststores:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic tls-client-profiles:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG apim-demo-tls-client-profile:1.0.0
   #apic tls-client-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic tls-server-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic keystores:get ea-watsonx-keystore --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic user-registries:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic user-registries:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json integration-keycloak
   #apic user-registries:update --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG integration-keycloak templates/template-apic-user-registry-settings.yaml
   #apic users:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY
   #apic users:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY integration-admin
   #apic users:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY new-user.yaml
   #apic gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --availability-zone $APIC_AVAILABILITY_ZONE
   #apic gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --availability-zone $APIC_AVAILABILITY_ZONE --format json eem-gateway-service
   #apic orgs:list --server $APIC_MGMT_SERVER
   #porgs=$(apic orgs:list --server $APIC_MGMT_SERVER | awk '$1=="cp4i-demo-org" { ++count } END { print count }')
   #if [ -z $porgs ] 
   #then 
   #   echo "does NOT exist"
   #else 
   #   echo "does exist"
   #fi 
   #apic orgs:get --server $APIC_MGMT_SERVER dummy-porg
   #apic orgs:delete --server $APIC_MGMT_SERVER sudhakar-provider-organization
   #apic identity-providers:list --server $APIC_MGMT_SERVER --scope provider
   #apic cloud-settings:get --server $APIC_MGMT_SERVER --output -
   #apic cloud-settings:update --server $APIC_MGMT_SERVER templates/template-apic-cloud-settings.yaml
   #apic tls-server-profiles:list-all --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG
   #apic tls-server-profiles:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json tls-server-profile-default:1.0.0
   #apic gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --availability-zone $APIC_AVAILABILITY_ZONE --format json api-gateway-service
   #apic tls-server-profiles:get --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --format json ea-watsonx-tls-server-profile:1.0.0
   #apic api-keys:list --server $APIC_MGMT_SERVER
   #apic gateway-extensions:implementation --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --gateway-service api-gateway-service --availability-zone $APIC_AVAILABILITY_ZONE
   echo "Invoking apic command..."
   #apic version --server $APIC_MGMT_SERVER --debug
   apic gateway-extensions:update /tmp/combined-gateway-extension.zip --server $APIC_MGMT_SERVER --scope org --org $APIC_ADMIN_ORG --gateway-service api-gateway-service --availability-zone $APIC_AVAILABILITY_ZONE
   echo "apic command completed."
}

POrgMode()
{
   #######################
   # PORG APIC VARIABLES #
   #######################
   local APIC_CATALOG='sandbox'
   local APIC_PORTAL_TYPE='drupal'
   local CATALOG_NAME="demo"
   local CATALOG_TITLE="Demo"
   local CATALOG_SUMMARY="Demo Catalog"
   local CONSUMER_ORG_NAME='AppDevOrg'
   local APP_NAME='CP4I-Demo-App'
   local APIC_ANALYTICS_SERVICE='analytics-service'
   #return
   ################################
   # LOGIN TO APIC WITH PORG USER #
   ################################
   #apic client-creds:clear
   echo "Login to APIC with regular user ..."
   if [ -z "$APIC_USER_NAME" ]
   then
      #local APIC_USER='integration-admin'
      local APIC_ORG='cp4i-demo-org'
      local APIC_REALM='provider/integration-keycloak'
      if [ -z "$APIC_API_KEY" ]
      then
         echo "   using SSO..."
         apic login --server $APIC_MGMT_SERVER --sso --context provider
      else
         echo "   using API Key..."
         apic login --server $APIC_MGMT_SERVER --sso --context provider --apiKey $APIC_API_KEY
      fi
   else
      local APIC_ORG='tz-provider-org'
      local APIC_REALM='provider/default-idp-2'
      echo "   using User & Password..."
      apic login --server $APIC_MGMT_SERVER --username $APIC_USER_NAME --password $APIC_USER_PWD --realm $APIC_REALM
   fi
   ###############################
   # TEST APIC CLI FOR PORG ROLE #
   ###############################
   apic -m engagement destinations:orgList --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format json --debug --output .
   #apic -m engagement destinations:orgGet --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format yaml HEZGPpUB2wfPcZXie1wF
   #apic -m engagement destinations:orgCreate --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE artifacts/Destination.yaml
   #apic -m engagement rules:orgList --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format yaml --output .
   #apic -m engagement rules:orgGet --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE --format json jm-pqJQB76XNSGqBamM_
   #apic -m engagement rules:orgCreate --server $APIC_MGMT_SERVER --org $APIC_ORG --analytics-service $APIC_ANALYTICS_SERVICE Rule.yaml
   #apic configured-gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog
   #apic configured-gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog eem-gateway-service
   #apic catalog-settings:get --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --format json
   #apic catalogs:get --s
   #apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG
   #apic catalogs:get --server $APIC_MGMT_SERVER --org $APIC_ORG test
   #apic gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ORG --availability-zone $APIC_AVAILABILITY_ZONE --scope org --format json eem-gateway-service
   #########################
   # PROCESS RESPONSE FILE #
   #########################
   #GATEWAY_SERVICE_NAME=$(jq -r '.name' "eem-gateway-service.json")
   #GATEWAY_SERVICE_TITLE=$(jq -r '.title' "eem-gateway-service.json")
   #GATEWAY_SERVICE_SUMMARY=$(jq -r '.summary' "eem-gateway-service.json")
   #GATEWAY_SERVICE_URL=$(jq -r '.url' "eem-gateway-service.json")
   #GATEWAY_SERVICE_TYPE=$(jq -r '.gateway_service_type' "eem-gateway-service.json")
   #INTEGRATION_URL=$(jq -r '.integration_url' "eem-gateway-service.json")
   #AVAILABILITY_ZONE_URL=$(jq -r '.availability_zone_url' "eem-gateway-service.json")
   #ENDPOINT=$(jq -r '.endpoint' "eem-gateway-service.json")
   #API_ENDPOINT_BASE=$(jq -r '.api_endpoint_base' "eem-gateway-service.json")
   #TLS_CLIENT_PROFILE_URL=$(jq -r '.tls_client_profile_url' "eem-gateway-service.json")
   #TLS_SERVER_PROFILE_URL=$(jq -r '.sni[0].tls_server_profile_url' "eem-gateway-service.json")
   #
   #ORG_URL=$(jq -r '.org_url' "sandbox.json")
   #CATALOG_URL=$(jq -r '.url' "sandbox.json")
   #
   #( echo "cat <<EOF" ; cat templates/template-apic-configured-gateway-service.yaml ;) | \
   #    GATEWAY_SERVICE_NAME=${GATEWAY_SERVICE_NAME} \
   #    GATEWAY_SERVICE_TITLE=${GATEWAY_SERVICE_TITLE} \
   #    GATEWAY_SERVICE_SUMMARY=${GATEWAY_SERVICE_SUMMARY} \
   #    GATEWAY_SERVICE_URL=${GATEWAY_SERVICE_URL} \
   #    GATEWAY_SERVICE_TYPE=${GATEWAY_SERVICE_TYPE} \
   #    INTEGRATION_URL=${INTEGRATION_URL} \
   #    AVAILABILITY_ZONE_URL=${AVAILABILITY_ZONE_URL} \
   #    ENDPOINT=${ENDPOINT} \
   #    API_ENDPOINT_BASE=${API_ENDPOINT_BASE} \
   #    TLS_CLIENT_PROFILE_URL=${TLS_CLIENT_PROFILE_URL} \
   #    TLS_SERVER_PROFILE_URL=${TLS_SERVER_PROFILE_URL} \
   #    sh > apic-configured-gateway-service.yaml
   #apic configured-gateway-services:create --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog apic-configured-gateway-service.yaml
   #apic gateway-services:get --server $APIC_MGMT_SERVER --org $APIC_ORG --format json eem-gateway-service
   #apic draft-products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG
   #apic catalogs:list --server $APIC_MGMT_SERVER --org $APIC_ORG --debug
   #apic products:list-all --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --scope catalog
   #apic configured-gateway-services:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $APIC_CATALOG --scope catalog
   #apic users:list --server $APIC_MGMT_SERVER --org $APIC_ORG --user-registry ${CATALOG_NAME}-catalog
   #apic consumer-orgs:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME
   #apic apps:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME
   #SUBS_LIST=$(apic subscriptions:list --server $APIC_MGMT_SERVER --org $APIC_ORG --catalog $CATALOG_NAME --consumer-org $CONSUMER_ORG_NAME --app $APP_NAME | awk '{ ++count } END { print count }')
   #echo $SUBS_LIST
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Set default values for input parameters                  #
############################################################
OP_MODE='ADMIN'

############################################################
# Set glocal variable                                      #
############################################################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'

ValidatePreReqs

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING="i:k:n:m:p:u:h"
# Get the options
while getopts ${OPTSTRING} option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Update instance name
         APIC_INST_NAME=$OPTARG;;
      k) # Set APIKey
         APIC_API_KEY=$OPTARG;;
      n) # Update namespace value
         APIC_NAMESPACE=$OPTARG;;
      m) # Set operation mode
         #OP_MODE=$OPTARG;;
         OP_MODE=$(echo "$OPTARG" | tr '[a-z]' '[A-Z]');;
      p) # Set APIC User Password
         APIC_USER_PWD=$OPTARG;;
      u) # Set APIC User Name
         APIC_USER_NAME=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

echo "Namespace:" $APIC_NAMESPACE
echo "Instance name:" $APIC_INST_NAME

############################################################
# GET APIC PLATFORM API                                    #
############################################################
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")

if [ "$OP_MODE" = "PORG" ]
then
   echo "Calling POrgMode function..."
   POrgMode
else
   if [ "$OP_MODE" != "ADMIN" ]; then echo "Invalid Operation Mode, ADMIN assumed"; fi;
   echo "Calling AdminMode function..."
   AdminMode
fi

echo "Done!"





