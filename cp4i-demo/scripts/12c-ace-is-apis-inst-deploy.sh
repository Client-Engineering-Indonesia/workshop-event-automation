#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is eabled"; fi;
read -p "Press <Enter> to execute script..."
ACE_NAMESPACE='tools'
echo "Copying Integration MQAPI PREM manifest..."
cp instances/${CP4I_VER}/10-ace-is-mqapi-prem-instance.yaml .
if [ ! -z "$CP4I_TRACING" ]
then
    echo "Configuring Tracing for Integration MQAPI PREM..."
    yq -i '.spec.telemetry.tracing.openTelemetry.enabled = true' 10-ace-is-mqapi-prem-instance.yaml
fi
echo "Deploying Integration MQAPI PREM..."
oc apply -f 10-ace-is-mqapi-prem-instance.yaml -n ${ACE_NAMESPACE}
echo "Deploying Integration MQAPI DFLT..."
oc apply -f instances/${CP4I_VER}/11-ace-is-mqapi-dflt-instance.yaml -n ${ACE_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 10-ace-is-mqapi-prem-instance.yaml
echo "Done! Check progress..."