#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set two environment variables called "EEM_ADMIN_PWD" and "ES_USER_PWD" with your maintrap info, using these command: 
# "export EEM_ADMIN_PWD=my-eem-admin-pwd"
# "export ES_USER_PWD=my-es-user-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
read -p "Press <Enter> to execute script..."
echo "Deploying Apache Flink..."
###################
# INPUT VARIABLES #
###################
FLINK_INST_NAME='ea-flink-demo'
FLINK_NAMESPACE='tools'
oc apply -f instances/${CP4I_VER}/common/21-ea-flink-instance.yaml
i=0
while [ -z $(oc get pods -n $FLINK_NAMESPACE | grep $FLINK_INST_NAME | awk '{print $2}') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get pods -n $FLINK_NAMESPACE | grep $FLINK_INST_NAME | awk '{print $2}') ]
then
    i=0
    while [ $(oc get pods -n $FLINK_NAMESPACE | grep $FLINK_INST_NAME | awk '{print $2}') != "1/1" ] && [ $i -lt 10 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get pods -n $FLINK_NAMESPACE | grep $FLINK_INST_NAME | awk '{print $2}') = "1/1" ]
    then
        echo "Apache Flink has been deployed"
        exit
    fi
fi
echo "Something is wrong!"