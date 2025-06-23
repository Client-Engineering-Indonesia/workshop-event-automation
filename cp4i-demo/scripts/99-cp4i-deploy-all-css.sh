#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
#if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#echo "CP4I_VER has been set to " $CP4I_VER
#read -p "Press <Enter> to execute script..."
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
echo "$timestamp Starting script"
echo "Enabling common services catalog source"
oc apply -f catalog-sources/${CP4I_VER}/02-common-services-catalog-source.yaml
echo "Waiting for common services catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/opencloud-operators -n openshift-marketplace 2>/dev/null 
do sleep 20; done
echo "Common services catalog source is ready"
echo "Enabling platform navigator catalog source"
oc apply -f catalog-sources/${CP4I_VER}/03-platform-navigator-catalog-source.yaml
echo "Waiting for platform navigator catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-integration-platform-navigator-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Platform navigator catalog source is ready"
echo "Enabling asset reposiroty catalog source"
oc apply -f catalog-sources/${CP4I_VER}/04-asset-repo-catalog-source.yaml
echo "Waiting for asset repository catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-integration-asset-repository-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Asset repository catalog source is ready"
echo "Enabling datapower catalog source"
oc apply -f catalog-sources/${CP4I_VER}/05-datapower-catalog-source.yaml
echo "Waiting for datapower catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-datapower-operator-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Datapower catalog source is ready"
echo "Enabling apic catalog source"
oc apply -f catalog-sources/${CP4I_VER}/07-api-connect-catalog-source.yaml
echo "Waiting for apic catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-apiconnect-catalog -n openshift-marketplace 2>/dev/null 
do sleep 20; done
echo "APIC catalog source is ready"
echo "Enabling event streams catalog source"
oc apply -f catalog-sources/${CP4I_VER}/08-event-streams-catalog-source.yaml
echo "Waiting for event streams catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-eventstreams-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Event streams catalog source is ready"
echo "Enabling event endpoint management catalog source"
oc apply -f catalog-sources/${CP4I_VER}/13-eem-catalog-source.yaml
echo "Waiting for event endpoint management catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-eventendpointmanagement-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Event endpoint management catalog source is ready"
echo "Enabling mq catalog source"
oc apply -f catalog-sources/${CP4I_VER}/09-mq-catalog-source.yaml
echo "Waiting for mq catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibmmq-operator-catalogsource -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "MQ catalog source is ready"
echo "Enabling app connect catalog source"
oc apply -f catalog-sources/${CP4I_VER}/10-app-connect-catalog-source.yaml
echo "Waiting for app connect catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/appconnect-operator-catalogsource -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "App connect catalog source is ready"
echo "Enabling flink catalog source"
oc apply -f catalog-sources/${CP4I_VER}/14-ea-flink-catalog-source.yaml
echo "Waiting for flink catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-eventautomation-flink-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Flink catalog source is ready"
echo "Enabling event processing catalog source"
oc apply -f catalog-sources/${CP4I_VER}/15-event-processing-catalog-source.yaml
echo "Waiting for event processing catalog source to be ready..."
while ! oc wait --for=jsonpath='{.status.connectionState.lastObservedState}'=READY \
      catalogsources/ibm-eventprocessing-catalog -n openshift-marketplace 2>/dev/null
do sleep 20; done
echo "Event processing catalog source is ready"
echo "Done!"
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
echo "$timestamp Script completed"