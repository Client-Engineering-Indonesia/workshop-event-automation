#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "2023.2" ]; then echo "This script is for CP4I v2023.2"; exit 1; fi;
ACE_NAMESPACE='tools'
CHECK_CONFIG=$(oc get configurations github-barauth --no-headers --ignore-not-found -n $ACE_NAMESPACE)
if [ -z $CHECK_CONFIG ]; then echo "BarAuth Config not set. You have to run script '11-ace-config-barauth-github' first."; exit 1; fi;
echo "Deploying Integration Runtimes..."
oc apply -f instances/${CP4I_VER}/common/18a-ace-is-aceivt-instance-fry.yaml
oc apply -f instances/${CP4I_VER}/common/18b-ace-is-aceivt-instance-fry.yaml
oc apply -f instances/${CP4I_VER}/common/19a-ace-is-aceivt-instance-bake.yaml