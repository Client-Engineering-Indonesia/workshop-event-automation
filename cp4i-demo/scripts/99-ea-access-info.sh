#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$EEM_ADMIN_PWD" ]; then echo "EEM_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EP_ADMIN_PWD" ]; then echo "EP_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
EA_NAMESPACE='tools'
ES_URL=$(oc get eventstreams es-demo -n $EA_NAMESPACE -o jsonpath={.status.adminUiUrl})
ES_USER_ID=$ES_INST_NAME-ibm-es-kafka-user
ES_USER_PWD=$(oc get secret $ES_USER_ID -n $EA_NAMESPACE -o jsonpath={.data.password} | base64 -d)
EEM_URL=$(oc get eventendpointmanagement eem-demo-mgr -n $EA_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="ui")].uri}')
EP_URL=$(oc get eventprocessing ep-demo -n $EA_NAMESPACE -o jsonpath='{.status.endpoints[?(@.name=="ui")].uri}')
JDBC_URI=$(oc get secret pgsqldemo-pguser-demouser -n $EA_NAMESPACE -o jsonpath='{.data.jdbc\-uri}' | base64 -d)
echo "Event Streams..."
echo "   UI URL:" $ES_URL
echo "   Admin user:" $ES_USER_ID
echo "   Admin password:" $ES_USER_PWD
echo "Event EndPoint Management..."
echo "   UI URL:" $EEM_URL
echo "   Admin user: eem-admin"
echo "   Admin password:" $EEM_ADMIN_PWD
echo "Event Processing..."
echo "   UI URL:" $EP_URL
echo "   Admin user: ep-admin"
echo "   Admin password:" $EP_ADMIN_PWD
echo "PostgreSQL Database..."
echo "   JDBC URI:" $JDBC_URI