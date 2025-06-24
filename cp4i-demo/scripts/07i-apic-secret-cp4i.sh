#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set the credential using environment variables called "USER_NAME" and "USER_PWD" using these commands: 
# "export USER_NAME=your-user"
# "export USER_PWD=user-password"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$USER_NAME" ]; then echo "USER_NAME is not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$USER_PWD" ]; then echo "USER_PWD is not set, it must be provided on the command line."; exit 1; fi;
echo "USER_NAME is set to" $USER_NAME
echo "USER_PWD is set to" $USER_PWD
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
( echo "cat <<EOF" ; cat templates/template-cp4i-apic-secret.yaml ;) | \
    APIC_BASE_URL=${APIC_BASE_URL} \
    APIC_USER_NAME=${USER_NAME} \
    APIC_USER_PWD=${USER_PWD} \
    APIC_TRUSTED_CERT=${APIC_TRUSTED_CERT} \
    sh > cp4i-apic-secret.yaml
echo "Creating Secret..."
oc apply -f cp4i-apic-secret.yaml -n ${ACE_NAMESPACE}
echo "Cleaning up temp files..."
rm -f ca.crt
rm -f cp4i-apic-secret.yaml
echo "API Secret for Assembly has been created"