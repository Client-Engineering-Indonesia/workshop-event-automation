#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    oc apply -f instances/${CP4I_VER}/common/13-ace-is-mqfwd-event-instance.yaml
    oc apply -f instances/${CP4I_VER}/common/14-ace-is-mock-backend-instance.yaml
else
    oc apply -f instances/${CP4I_VER}/common/tracing/13-ace-is-mqfwd-event-tracing-instance.yaml
    oc apply -f instances/${CP4I_VER}/common/tracing/14-ace-is-mock-backend-tracing-instance.yaml
fi
echo "Done!"