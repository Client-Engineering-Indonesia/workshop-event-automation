#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled, no need to run this script."; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "2022.2" ]; then echo "This script is for CP4I v2022.2"; exit 1; fi;
echo "Registering APIC instance with Operations Dashboard..."
###################
# INPUT VARIABLES #
###################
NS="tools"
CAPABILITY_INST_NAME="apim-demo"
CAPABILITY_POD_NAME="apim-demo-gw-0"
#######################
# CREATE REGISTRATION #
#######################
echo "Create Secret Template..."
oc create secret generic icp4i-od-store-cred -n $NS --from-literal=icp4i-od-cacert.pem="empty" --from-literal=username="empty" --from-literal=password="empty" --from-literal=tracingUrl="empty"
(echo "cat <<EOF" ; cat templates/template-od-registration.yaml ;) | \
    NS=${NS} \
    CAPABILITY_INST_NAME=${CAPABILITY_INST_NAME} \
    CAPABILITY_POD_NAME=${CAPABILITY_POD_NAME} \
    sh > od-registration-apic.yaml
echo "Creating OD Registraion Binding..."
oc apply -f od-registration-apic.yaml
echo "Cleaning up temp files..."
rm -f od-registration-apic.yaml
echo "Registration has been completed."