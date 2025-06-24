#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
#if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#echo "CP4I_VER has been set to " $CP4I_VER
#read -p "Press <Enter> to execute script..."
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
echo "$timestamp Starting script"
echo "Installing common services operator"
oc apply -f subscriptions/${CP4I_VER}/00-common-service-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment/ibm-common-service-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for common services operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null 
do sleep 20; done
echo "Common services operator is ready"
echo "Installing platform navigator operator"
oc apply -f subscriptions/${CP4I_VER}/01-platform-navigator-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-integration-platform-navigator-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for platform navigator operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Platform navigator operator is ready"
echo "Installing asset repository operator"
oc apply -f subscriptions/${CP4I_VER}/02-asset-repo-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-integration-asset-repository-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for asset repository operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done            
echo "Asset repository operator is ready"
echo "Installing datapower operator"
oc apply -f subscriptions/${CP4I_VER}/03-datapower-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment datapower-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for datapower operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Datapower operator is ready"
echo "Installing apic operator"
oc apply -f subscriptions/${CP4I_VER}/04-api-connect-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-apiconnect -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for apic operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 30; done
echo "APIC operator is ready"
echo "Installing event streams operator"
oc apply -f subscriptions/${CP4I_VER}/05-event-streams-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment eventstreams-cluster-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for event streams operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Event Streams operator is ready"
echo "Installing event endpoint managenent operator"
oc apply -f subscriptions/${CP4I_VER}/09-eem-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-eem-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for event endpoint management operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Event endpoint management operator is ready"
echo "Installing mq operator"
oc apply -f subscriptions/${CP4I_VER}/06-mq-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-mq-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for mq operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "MQ operator is ready"
echo "Installing app connect operator"
oc apply -f subscriptions/${CP4I_VER}/07-app-connect-subscription.yaml 
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-appconnect-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for app connect operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "App connect operator is ready"
echo "Installing flink operator"
oc apply -f subscriptions/${CP4I_VER}/10-ea-flink-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment flink-kubernetes-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for flink operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Flink operator is ready"
echo "Installing event processing operator"
oc apply -f subscriptions/${CP4I_VER}/11-event-processing-subscription.yaml
echo "Getting operator version..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]; do 
      sleep 3; SUB_NAME=$(oc get deployment ibm-ep-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for event processing operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded \
      csv/$SUB_NAME 2>/dev/null
do sleep 20; done
echo "Event processing operator is ready"
echo "Done!"
timestamp=$(date +%Y-%m-%d_%H:%M:%S)
echo "$timestamp Script completed"