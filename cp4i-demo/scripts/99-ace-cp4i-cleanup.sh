#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "2023.2" ]; then echo "This script is for CP4I v2023.2"; exit 1; fi;
ACE_NAMESPACE='tools'
oc get IntegrationRuntimes --no-headers --ignore-not-found -n $ACE_NAMESPACE | awk -v acens="${ACE_NAMESPACE}" '$1 ~ "jgr.*cp4i" { system("oc delete IntegrationRuntime " $1 " -n " acens) }'