#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set an environment variables called "APIC_API_KEY" using this command: 
# "export APIC_API_KEY=my-apic-api-key"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$APIC_API_KEY" ]; then echo "APIC_API_KEY not set, it must be provided on the command line."; exit 1; fi;
echo "APIC_API_KEY is set to" $APIC_API_KEY
read -p "Press <Enter> to execute script..."
echo "Building API Secret for Assembly"
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
ACE_NAMESPACE='tools'
#################
# CREATE SECRET #
#################
APIC_FULL_BASE_URL=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n ${APIC_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="platformApi")].uri}')
APIC_BASE_URL=$(echo ${APIC_FULL_BASE_URL%/*})
echo "APIC BASE URL: " $APIC_BASE_URL 
APIC_SECRET_NAME=$(oc get ManagementCluster "${APIC_INST_NAME}-mgmt" -n ${APIC_NAMESPACE} -o jsonpath='{.status.endpoints[?(@.name=="platformApi")].secretName}')
oc extract secret/${APIC_SECRET_NAME} -n ${APIC_NAMESPACE} --keys=ca.crt
APIC_TRUSTED_CERT=`awk '{print "    "$0}' ca.crt`
( echo "cat <<EOF" ; cat templates/template-cp4i-apic-secret-v2.yaml ;) | \
    APIC_BASE_URL=${APIC_BASE_URL} \
    APIC_API_KEY=${APIC_API_KEY} \
    APIC_TRUSTED_CERT=${APIC_TRUSTED_CERT} \
    sh > cp4i-apic-secret.yaml
echo "Creating Secret..."
oc apply -f cp4i-apic-secret.yaml -n ${ACE_NAMESPACE}
echo "Cleaning up temp files..."
rm -f ca.crt
rm -f cp4i-apic-secret.yaml
echo "API Secret for Assembly has been created"