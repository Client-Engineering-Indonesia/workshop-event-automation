#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "2022.2" ]; then echo "This script is for CP4I v2022.2"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/tracing/04-apic-emm-tracing-hpa-test-billing-instance.yaml
else
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/04-apic-emm-hpa-test-billing-instance.yaml
fi
if [ $(oc get apiconnectcluster --no-headers -n tools | awk '{print $3}') = "Ready" ]
then
    echo "API Connect is Ready."
else
    if [ -z "$CP4I_TRACING" ]
    then
        while [ $(oc get apiconnectcluster --no-headers -n tools | awk '{print $2}') != "6/9" ]
        do
            echo "Checking status..."
            echo "Sleeping for five minutes..."
            sleep 300
        done
        while [ $(oc get gatewaycluster --no-headers -n tools | awk '{print $2}') != "1/2" ]
        do
            echo "Checking status..."
            echo "Sleeping for one minute..."
            sleep 60
        done
        echo "API Connect is Ready for OD Configuration."
        curl --ssl-reqd \
             --url "smtp://smtp.mailtrap.io:2525" \
             --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
             --mail-from cp4i-admin@ibm.com \
             --mail-rcpt cp4i-user@ibm.com \
             --upload-file email-files/07a-apic-inst-deploy-od-success.txt
    else
        while [ $(oc get apiconnectcluster --no-headers -n tools | awk '{print $3}') != "Ready" ]
        do
            echo "Checking status..." $i
            echo "Sleeping for five minutes..."
            sleep 300
        done
        echo "API Connect is Ready."
        curl --ssl-reqd \
             --url "smtp://smtp.mailtrap.io:2525" \
             --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
             --mail-from cp4i-admin@ibm.com \
             --mail-rcpt cp4i-user@ibm.com \
             --upload-file email-files/07c-apic-deploy-progress-od-success.txt
    fi
fi
echo "Done!"