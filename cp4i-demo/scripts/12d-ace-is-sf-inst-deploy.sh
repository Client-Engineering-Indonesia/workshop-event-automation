#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is eabled"; fi;
if [ -z "$SF_CONNECTOR" ]; then echo "SalesForce Integration is NOT enabled"; else echo "SalesForce Integration is enabled"; fi;
read -p "Press <Enter> to execute script..."
echo "Set BAR File for SalesForce Integration..."
if [ -z "$SF_CONNECTOR" ]
then
    echo "Using BAR File without SF Integration..."
    BAR_FILE='SFLeadsX.bar'
else
    echo "Using BAR File with SF Integration..."
    BAR_FILE='SFLeads.bar'
fi
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/12b-ace-is-designer-sfleads-instance.yaml ;) | \
BAR_FILE=${BAR_FILE} \
sh > 12b-ace-is-designer-sfleads-instance.yaml
if [ ! -z "$CP4I_TRACING" ]
then
    echo "Configuring Tracing for Integration SFLEADS..."
    yq -i '.spec.telemetry.tracing.openTelemetry.enabled = true' 12b-ace-is-designer-sfleads-instance.yaml
fi
echo "Deploying Integration SFLEADS..."
oc apply -f 12b-ace-is-designer-sfleads-instance.yaml -n tools
echo "Cleaning up temp files..."
rm -f 12b-ace-is-designer-sfleads-instance.yaml
echo "Done! Check progress..."