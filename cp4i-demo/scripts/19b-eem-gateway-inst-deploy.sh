#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
read -p "Press <Enter> to execute script..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
EEM_GATEWAY_ROUTE=$(oc get route "${EEM_INST_NAME}-ibm-eem-gateway" -n $EEM_NAMESPACE --ignore-not-found -o jsonpath="{.spec.host}") 
if [[ ! -z "${EEM_GATEWAY_ROUTE}" ]]
then
    ( echo "cat <<EOF" ; cat instances/${CP4I_VER}/20-eem-gateway-instance.yaml ;) | \
        EEM_GATEWAY_ROUTE=${EEM_GATEWAY_ROUTE} \
        sh > temp-eem-gateway-instance.yaml
    oc apply -f temp-eem-gateway-instance.yaml -n ${EEM_NAMESPACE}
    rm -f temp-eem-gateway-instance.yaml
else
    echo "EEM Manager instance ${EEM_INST_NAME} is not deployed in namespace ${EEM_NAMESPACE}. Check and try again."
fi