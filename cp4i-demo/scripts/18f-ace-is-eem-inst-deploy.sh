#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EEM_APIC_INT" ]; then echo "EMM is not configured."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is enabled"; else echo "CP4I Tracing is NOT eabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    oc apply -f instances/${CP4I_VER}/common/tracing/15b-ace-is-kafka-email-tracing-instance.yaml
else
    oc apply -f instances/${CP4I_VER}/common/15b-ace-is-kafka-email-instance.yaml
fi
echo "Done!"