#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$EA_OIDC" ]
then
   oc get secret eem-demo-mgr-ibm-eem-user-credentials -n tools -o jsonpath={.data."user-credentials\.json"} | base64 -d > user-credentials.json
   EEM_ADMIN_PWD=$(jq -r '.users[] | select(.username=="eem-admin") | .password' user-credentials.json)
   rm -f user-credentials.json
   oc get secret ep-demo-ibm-ep-user-credentials -n tools -o jsonpath={.data."user-credentials\.json"} | base64 -d > user-credentials.json
   EP_ADMIN_PWD=$(jq -r '.users[] | select(.username=="ep-admin") | .password' user-credentials.json)
   rm -f user-credentials.json
fi
#if [ -z "$EEM_ADMIN_PWD" ] && [ -z "$EA_OIDC" ]; then echo "EEM_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$EP_ADMIN_PWD" ] && [ -z "$EA_OIDC" ]; then echo "EP_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
ES_URL=$(oc get eventstreams es-demo -n tools -o jsonpath={.status.adminUiUrl})
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1")
      ES_USER_ID=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.username} | base64 -d)
      ES_USER_PWD=$(oc get secret integration-admin-initial-temporary-credentials -n ibm-common-services -o jsonpath={.data.password} | base64 -d)
      ;;
   *)
      ES_USER_ID=$(oc get secret ibm-iam-bindinfo-platform-auth-idp-credentials -n tools -o jsonpath={.data.admin_username} | base64 -d)
      ES_USER_PWD=$(oc get secret ibm-iam-bindinfo-platform-auth-idp-credentials -n tools -o jsonpath={.data.admin_password} | base64 -d)
      ;;
esac
#EEM_URL=$(oc get eventendpointmanagement eem-demo-mgr -n tools -o jsonpath='{range .status.endpoints[?(@.name=="ui")]}{.uri}{end}')
EEM_URL=$(oc get eventendpointmanagement eem-demo-mgr -n tools -o jsonpath='{.status.endpoints[?(@.name=="ui")].uri}')
#EP_URL=$(oc get eventprocessing ep-demo -n tools -o jsonpath='{range .status.endpoints[?(@.name=="ui")]}{.uri}{end}')
EP_URL=$(oc get eventprocessing ep-demo -n tools -o jsonpath='{.status.endpoints[?(@.name=="ui")].uri}')
JDBC_URI=$(oc get secret pgsqldemo-pguser-demouser -n pgsql -o jsonpath='{.data.jdbc\-uri}' | base64 -d)
echo "Event Streams..."
echo "   UI URL:" $ES_URL
echo "   Admin user:" $ES_USER_ID
echo "   Admin password:" $ES_USER_PWD
echo "Event EndPoint Management..."
echo "   UI URL:" $EEM_URL
if [ -z "$EA_OIDC" ]
then
   echo "   Admin user: eem-admin"
   echo "   Admin password:" $EEM_ADMIN_PWD
else
   echo "   Admin user:" $ES_USER_ID
   echo "   Admin password:" $ES_USER_PWD
fi
echo "Event Processing..."
echo "   UI URL:" $EP_URL
if [ -z "$EA_OIDC" ]
then
   echo "   Admin user: ep-admin"
   echo "   Admin password:" $EP_ADMIN_PWD
else
   echo "   Admin user:" $ES_USER_ID
   echo "   Admin password:" $ES_USER_PWD
fi
echo "PostgreSQL Database..."
echo "   JDBC URI:" $JDBC_URI