#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set two environment variables called "EEM_ADMIN_PWD" and "ES_USER_PWD" with your maintrap info, using these command: 
# "export EEM_ADMIN_PWD=my-eem-admin-pwd"
# "export ES_USER_PWD=my-es-user-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EEM_ADMIN_PWD" ]; then echo "EEM_ADMIN_PWD not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EEM_USER_PWD" ]; then echo "ES_USER_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "OCP_TYPE is set to" $OCP_TYPE
echo "EEM_ADMIN_PWD is set to" $EEM_ADMIN_PWD
echo "EEM_USER_PWD is set to" $EEM_USER_PWD
read -p "Press <Enter> to execute script..."
echo "Deploying EEM Manager..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/19-eem-manager-local-instance.yaml
i=0
while [ -z $(oc get pods -n $EEM_NAMESPACE | grep ${EEM_INST_NAME}-ibm-eem-manager | awk '{print $2}') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get pods -n $EEM_NAMESPACE | grep ${EEM_INST_NAME}-ibm-eem-manager | awk '{print $2}') ]
then
    i=0
    while [ $(oc get pods -n $EEM_NAMESPACE | grep ${EEM_INST_NAME}-ibm-eem-manager | awk '{print $2}') != "1/1" ] && [ $i -lt 10 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get pods -n $EEM_NAMESPACE | grep ${EEM_INST_NAME}-ibm-eem-manager | awk '{print $2}') = "1/1" ]
    then
        (echo "cat <<EOF" ; cat templates/template-eem-user-credentials.json ;) | \
           EEM_ADMIN_PWD=${EEM_ADMIN_PWD} \
           EEM_USER_PWD=${EEM_USER_PWD} \
           sh > eem-user-credentials.json
        SECRET_DATA_BASE64=$(base64 -i eem-user-credentials.json | tr -d '\n')
        echo $SECRET_DATA_BASE64
        oc patch secret ${EEM_INST_NAME}-ibm-eem-user-credentials -n $EEM_NAMESPACE --patch '{"data":{"user-credentials.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
#        oc patch secret ${EEM_INST_NAME}-ibm-eem-user-credentials -n $EEM_NAMESPACE --patch '{"data":{"user-credentials.json":"ewogICAgInVzZXJzIjogWwogICAgICAgIHsKICAgICAgICAgICAgInVzZXJuYW1lIjogImVlbS1hZG1pbiIsCiAgICAgICAgICAgICJwYXNzd29yZCI6ICJUaDEkSVNUaDNBZG0xblBhJFNXMFJkIgogICAgICAgIH0sCiAgICAgICAgewogICAgICAgICAgICAidXNlcm5hbWUiOiAiZXMtdXNlciIsCiAgICAgICAgICAgICJwYXNzd29yZCI6ICJNeVUkZXJQYVMkV29yRCIKICAgICAgICB9CiAgICBdCn0K"}}' --type=merge
        SECRET_DATA_BASE64=$(base64 -i resources/10-eem-user-roles.json | tr -d '\n')
        echo $SECRET_DATA_BASE64
        oc patch secret ${EEM_INST_NAME}-ibm-eem-user-roles -n $EEM_NAMESPACE --patch '{"data":{"user-mapping.json":"'$SECRET_DATA_BASE64'"}}' --type=merge
#        oc patch secret ${EEM_INST_NAME}-ibm-eem-user-roles -n $EEM_NAMESPACE --patch '{"data":{"user-mapping.json":"ewogICAgIm1hcHBpbmdzIjogWwogICAgICAgIHsKICAgICAgICAgICAgImlkIjogImVlbS1hZG1pbiIsCiAgICAgICAgICAgICJyb2xlcyI6IFsKICAgICAgICAgICAgICAgICJhdXRob3IiCiAgICAgICAgICAgIF0KICAgICAgICB9LAogICAgICAgIHsKICAgICAgICAgICAgImlkIjogImVzLXVzZXIiLAogICAgICAgICAgICAicm9sZXMiOiBbCiAgICAgICAgICAgICAgICAidmlld2VyIgogICAgICAgICAgICBdCiAgICAgICAgfQogICAgXQp9"}}' --type=merge
        echo "Cleaning up temp files..." 
        rm -f eem-user-credentials.json
        echo "EEM Manager has been deployed"
        exit
    fi
fi
echo "Something is wrong!"
