#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
if [ -z "$PGSQL_DB" ]; then echo "PGSQL DB is NOT installed"; else echo "PGSQL DB Integration is enabled"; fi;
read -p "Press <Enter> to execute script..."
echo "Get the proper Integration Runtime manifest..."
if [ -z "$PGSQL_DB" ]
then
    echo "Using manifest with mock backend..."
    cp instances/${CP4I_VER}/14-ace-is-mock-backend-instance.yaml 14-ace-is-backend-instance.yaml
else
    echo "Using manifest with PGSQL connectivity..."
    cp instances/${CP4I_VER}/14-ace-is-pgsql-backend-instance.yaml 14-ace-is-backend-instance.yaml    
fi
if [ ! -z "$CP4I_TRACING" ]
then
    echo "Configuring Tracing for Backend Integration..."
    yq -i '.spec.telemetry.tracing.openTelemetry.enabled = true' 14-ace-is-backend-instance.yaml
fi
echo "Deploying Backend Integration..."
oc apply -f 14-ace-is-backend-instance.yaml -n tools
echo "Cleaning up temp files..."
rm -f 14-ace-is-backend-instance.yaml
echo "Done! Check progress..."