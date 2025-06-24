#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set five environment variables called "ZONE_NAME", "CLUSTER_NAME", "INSTANA_APP_KEY, "INSTANA_SVC_ENDPOINT", "INSTANA_SVC_PORT"
# based on the information you gather from the Instana environment you will be connecting to, using these command: 
# "export ZONE_NAME=<my-zone-name>"
# "export CLUSTER_NAME=<my-cluster-name>"
# "export INSTANA_APP_KEY=<instana-app-key>"
# "export INSTANA_SVC_ENDPOINT=<instana-service-endpoint>"
# "export INSTANA_SVC_PORT=<instana-service-port>"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! -z "$CP4I_TRACING" ]; then echo "Tracing is disabled."; exit; fi;
#if [ -z $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '$2=="Running" { ++count } END { print count }') ]; then echo "Jaegar instance is NOT running. Check tracing installation."; exit 1; fi; 
if [ -z "$ZONE_NAME" ]; then echo "ZONE_NAME not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$CLUSTER_NAME" ]; then echo "CLUSTER_NAME not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_APP_KEY" ]; then echo "INSTANA_APP_KEY not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_SVC_ENDPOINT" ]; then echo "INSTANA_SVC_ENDPOINT not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_SVC_PORT" ]; then echo "INSTANA_SVC_PORT not set, it must be provided on the command line."; exit 1; fi;
echo "ZONE_NAME is set to" $ZONE_NAME
echo "CLUSTER_NAME is set to" $CLUSTER_NAME
echo "INSTANA_APP_KEY is set to" $INSTANA_APP_KEY
echo "INSTANA_SVC_ENDPOINT is set to" $INSTANA_SVC_ENDPOINT
echo "INSTANA_SVC_PORT is set to" $INSTANA_SVC_PORT
read -p "Press <Enter> to execute script..."
echo "Installing Instana dependencies..."
oc new-project instana-agent
oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
#b=$(oc get csv --no-headers -n instana-agent | awk '$(NF)=="Succeeded" { ++count } END { print count }')
#if [ -z $b ]; then b=0; fi;
#let "b+=1"
b=0
i=0
#########################
# CREATE AGENT INSTANCE #
#########################
echo "Creating Instana Agent instance..."
(echo "cat <<EOF" ; cat templates/template-instana-agent.yaml ;) | \
    ZONE_NAME=${ZONE_NAME} \
    CLUSTER_NAME=${CLUSTER_NAME} \
    INSTANA_APP_KEY=${INSTANA_APP_KEY} \
    INSTANA_SVC_ENDPOINT=${INSTANA_SVC_ENDPOINT} \
    INSTANA_SVC_PORT=${INSTANA_SVC_PORT} \
    sh > instana-agent.yaml
oc apply -f instana-agent.yaml
echo "Cleaning up temp file..."
rm -f instana-agent.yaml
echo "Done! Check progress..."