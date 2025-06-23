#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled, no need to run this script."; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
#if [ "$CP4I_VER" != "2022.4" ]; then echo "This script is for CP4I v2022.4"; exit 1; fi;
#if [ ! "$CP4I_VER" =~ ^("2022.4"|"2023.2"|"2023.4")$ ]; then echo "This script is for CP4I v2022.4 or newer"; exit 1; fi;
case "$CP4I_VER" in
   "2022.4" | "2023.2" | "2023.4")
      read -p "Press <Enter> to execute script..."
      echo "Configuring APIC instance to communicate with Instana..."
      ;;
   *)
      echo "This script is for CP4I v2022.4 or newer"
      exit 1
      ;;
esac
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
#########################
# UPDATE DP STATEFULSET #
#########################
echo "Configuring APIC instance to work with Instana..."
oc get statefulset "${APIC_INST_NAME}-gw" -n $APIC_NAMESPACE -o json > gw-statefulset.json
jq '.spec.template.spec.containers |= map(select(.name=="jaeger-tracing-agent").env += [{
   "name": "INSTANA_AGENT_HOST",
   "valueFrom": {
   "fieldRef": {
   "apiVersion": "v1",
   "fieldPath": "status.hostIP" }}
   }])' gw-statefulset.json > gw-statefulset-updated.json
echo "Updating DataPower StatefulSet..."
oc apply -f gw-statefulset-updated.json
echo "Cleaning up temp files..."
rm -f gw-statefulset.json
rm -f gw-statefulset-updated.json
echo "Configuration has been completed."