#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
echo "Deploying License Reporter..."
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/00-license-reporter-instance.yaml
if [ "$CP4I_VER" = "2023.4" ]
then 
    NUM_CONT_READY='2/2'
else
    NUM_CONT_READY='3/3'
fi
i=0
while [ -z $(oc get pods -n ibm-common-services | grep ibm-license-service-reporter-instance | awk '{print $2}') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get pods -n ibm-common-services | grep ibm-license-service-reporter-instance | awk '{print $2}') ]
then
    i=0
    while [ $(oc get pods -n ibm-common-services | grep ibm-license-service-reporter-instance | awk '{print $2}') != "$NUM_CONT_READY" ] && [ $i -lt 10 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get pods -n ibm-common-services | grep ibm-license-service-reporter-instance | awk '{print $2}') = "$NUM_CONT_READY" ]
    then
        oc get OperandConfig common-service -n ibm-common-services -o json > opconfig.json
        jq '.spec.services |= map(select(.name=="ibm-licensing-operator").spec.IBMLicenseServiceReporter = {})' \
            opconfig.json > opconfig-updated.json
        echo "Update Common-Service Operand Configuration..."
        oc apply -f opconfig-updated.json
        echo "Cleaning up temp files..." 
        rm -f opconfig.json
        rm -f opconfig-updated.json
        echo "License Reporter has been deployed"
        exit
    fi
fi
echo "Something is wrong!"