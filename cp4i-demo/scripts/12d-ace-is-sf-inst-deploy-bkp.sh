#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is eabled"; fi;
if [ -z "$SF_CONNECTOR" ]; then echo "SalesForce Integration is NOT enabled"; else echo "SalesForce Integration is enabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    if [ -z "$SF_CONNECTOR" ]
    then
        echo "Deploying Integration SFLEADS without SF and no tracing..."
        oc apply -f instances/${CP4I_VER}/common/12b-ace-is-designer-sfleads-instance.yaml
    else
        echo "Deploying Integration SFLEADS with SF and no tracing..."
        oc apply -f instances/${CP4I_VER}/common/12a-ace-is-designer-sfleads-instance.yaml
    fi
else
    if [ -z "$SF_CONNECTOR" ]
    then
        echo "Deploying Integration SFLEADS without SF and tracing enabled..."
        oc apply -f instances/${CP4I_VER}/common/tracing/12b-ace-is-designer-sfleads-tracing-instance.yaml
    else
        echo "Deploying Integration SFLEADS with SF and tracing enabled..."
        oc apply -f instances/${CP4I_VER}/common/tracing/12a-ace-is-designer-sfleads-tracing-instance.yaml
    fi
fi
echo "Done!"