#!/bin/sh
if [ -z $1 ]; then echo "Argument is missing"; exit 1; fi;
echo "Installing ElasticSearch dependencies..."
oc apply -f resources/00a-elasticsearch-namespace.yaml
oc apply -f resources/00b-elasticsearch-operatorgroup.yaml
oc apply -f resources/00c-elasticsearch-subscription.yaml
i=0
echo "Waiting for the ElasticSearch dependencies to get ready..."
while [ -z $(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count } END { print count }') ]
then
    i=0
    while [ $(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $1 ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
fi
echo "Elastic install ended."