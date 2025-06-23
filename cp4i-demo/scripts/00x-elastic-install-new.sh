#!/bin/sh
#if [ -z $1 ]; then echo "Argument is missing"; exit 1; fi;
echo "Installing ElasticSearch dependencies..."
oc apply -f resources/00a-elasticsearch-namespace.yaml
oc apply -f resources/00b-elasticsearch-operatorgroup.yaml
oc apply -f resources/00c-elasticsearch-subscription.yaml
echo "Waiting for the ElasticSearch dependencies to get ready..."
SUB_NAME=''
while [ -z "$SUB_NAME" ]
do 
    sleep 5
    SUB_NAME=$(oc get deployment elasticsearch-operator -n openshift-operators-redhat --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')
done
echo "Operator: " $SUB_NAME
echo "Waiting for ElasticSearch operator to be ready..."
while ! oc wait --for=jsonpath='{.status.phase}'=Succeeded csv/$SUB_NAME 2>/dev/null
do 
    sleep 30
done  
echo "ElasticSearch operator is ready."