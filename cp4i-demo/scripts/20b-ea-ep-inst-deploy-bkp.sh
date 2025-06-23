#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set a environment variables called "EP_ADMIN_PWD" using this command: 
# "export EP_ADMIN_PWD=my-eem-admin-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EP_ADMIN_PWD" ]; then echo "EP_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "OCP_TYPE is set to" $OCP_TYPE
echo "EP_ADMIN_PWD is set to" $EP_ADMIN_PWD
read -p "Press <Enter> to execute script..."
echo "Deploying Event Processing..."
###################
# INPUT VARIABLES #
###################
EP_INST_NAME='ep-demo'
EP_NAMESPACE='tools'
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/22-event-processing-instance.yaml
i=0
while [ -z $(oc get pods -n $EP_NAMESPACE | grep ${EP_INST_NAME}-ibm-ep-sts | awk '{print $2}') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get pods -n $EP_NAMESPACE | grep ${EP_INST_NAME}-ibm-ep-sts | awk '{print $2}') ]
then
    i=0
    while [ $(oc get pods -n $EP_NAMESPACE | grep ${EP_INST_NAME}-ibm-ep-sts | awk '{print $2}') != "2/2" ] && [ $i -lt 10 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get pods -n $EP_NAMESPACE | grep ${EP_INST_NAME}-ibm-ep-sts | awk '{print $2}') = "2/2" ]
    then
       (echo "cat <<EOF" ; cat templates/template-ep-user-credentials.json ;) | \
           EP_ADMIN_PWD=${EP_ADMIN_PWD} \
           sh > ep-user-credentials.json
        SECRET_DATA_BASE64=$(base64 -i ep-user-credentials.json | tr -d '\n')
        oc patch secret ${EP_INST_NAME}-ibm-ep-user-credentials -n $EP_NAMESPACE --patch '{"data":{"user-credentials.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
#        oc patch secret ${EP_INST_NAME}-ibm-ep-user-credentials -n $EP_NAMESPACE --patch '{"data":{"user-credentials.json":"ewogICAgInVzZXJzIjogWwogICAgICAgIHsKICAgICAgICAgICAgInVzZXJuYW1lIjogImVwLWFkbWluIiwKICAgICAgICAgICAgInBhc3N3b3JkIjogIlRoMSRJU1RoM0FkbTFuUGEkU1cwUmQiCiAgICAgICAgfQogICAgXQp9Cg=="}}' --type=merge
        SECRET_DATA_BASE64=$(base64 -i resources/11-ep-user-roles.json | tr -d '\n')
        oc patch secret ${EP_INST_NAME}-ibm-ep-user-roles -n $EP_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
#        oc patch secret ${EP_INST_NAME}-ibm-ep-user-roles -n $EP_NAMESPACE --patch '{"data":{"user-mapping.json":"ewogICAgIm1hcHBpbmdzIjogWwogICAgICAgIHsKICAgICAgICAgICAgImlkIjogImVwLWFkbWluIiwKICAgICAgICAgICAgInJvbGVzIjogWwogICAgICAgICAgICAgICAgInVzZXIiCiAgICAgICAgICAgIF0KICAgICAgICB9CiAgICBdCn0="}}' --type=merge
        echo "Cleaning up temp files..." 
        rm -f ep-user-credentials.json
        echo "Event Processing has been deployed"
        exit
    fi
fi
echo "Something is wrong!"
