#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is eabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    echo "Deploying Integration MQAPI PREM without tracing..."
    oc apply -f instances/${CP4I_VER}/common/10-ace-is-mqapi-prem-instance.yaml
else
    echo "Deploying Integration MQAPI PREM with tracing enabled..."
    oc apply -f instances/${CP4I_VER}/common/tracing/10-ace-is-mqapi-prem-tracing-instance.yaml
fi
echo "Deploying Integration MQAPI DFLT..."
oc apply -f instances/${CP4I_VER}/common/11-ace-is-mqapi-dflt-instance.yaml
echo "Done!"