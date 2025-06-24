#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
read -p "Press <Enter> to execute script..."
ACE_NAMESPACE='tools'
echo "Copying Integration manifest..."
cp instances/${CP4I_VER}/15a-ace-is-kafka-email-instance.yaml .
if [ ! -z "$CP4I_TRACING" ]
then
    echo "Configuring Tracing for Integrations..."
    yq -i '.spec.telemetry.tracing.openTelemetry.enabled = true' 15a-ace-is-kafka-email-instance.yaml
fi
echo "Deploying Integration..."
oc apply -f 15a-ace-is-kafka-email-instance.yaml -n ${ACE_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 15a-ace-is-kafka-email-instance.yaml
echo "Done! Check progress..."