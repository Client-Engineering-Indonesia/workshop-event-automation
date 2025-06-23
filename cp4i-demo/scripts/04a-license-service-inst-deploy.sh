#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
read -p "Press <Enter> to execute script..."
b=$(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }')
let "b+=1"
echo $b 
echo "Installing License Service Subscription..."
oc apply -f subscriptions/${CP4I_VER}/00-license-service-subscription.yaml
i=0
while [ -z $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') ]
then
    i=0
    while [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $b ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $b ]
    then
        echo "Deploying License Service..."
        oc apply -f instances/${CP4I_VER}/common/00-license-service-instance.yaml
        i=0
        while [ -z $(oc get pods -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}') ] && [ $i -lt 5 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for one minute..."
            sleep 60
            let "i++"
        done
        if [ ! -z $(oc get pods -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}') ]
        then
            i=0
            while [ $(oc get pods -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}') != "1/1" ] && [ $i -lt 10 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for one minute..."
                sleep 60
                let "i++"
            done
            if [ $(oc get pods -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}') = "1/1" ]
            then
                echo "License Service has been deployed"
                exit
            fi
        fi
    fi
fi    
echo "Something is wrong!"