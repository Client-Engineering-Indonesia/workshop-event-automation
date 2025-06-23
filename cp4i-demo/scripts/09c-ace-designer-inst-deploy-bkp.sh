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
echo "OCP_TYPE is set to" $OCP_TYPE
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
echo "Deploying ACE Designer instance..."
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/08-ace-designer-local-ai-instance.yaml
i=0
echo "Waiting for the ACE Designer instance to get ready..."
while [ $(oc get designerauthoring --no-headers -n tools | awk '{print $5}') != "Ready" ] && [ $i -lt 15 ]
do
    echo "Checking status..." $i
    echo "Sleeping for two minutes..."
    sleep 120
    let "i++"
done
if [ $(oc get designerauthoring --no-headers -n tools | awk '{print $5}') != "Ready" ]
then
    echo "Something is wrong!"
    curl --ssl-reqd \
         --url "smtp://smtp.mailtrap.io:2525" \
         --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
         --mail-from cp4i-admin@ibm.com \
         --mail-rcpt cp4i-user@ibm.com \
         --upload-file email-files/09c-ace-designer-inst-deploy-failure.txt
else
    echo "ACE Designer Authoring Tool is Ready."
    curl --ssl-reqd \
         --url "smtp://smtp.mailtrap.io:2525" \
         --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
         --mail-from cp4i-admin@ibm.com \
         --mail-rcpt cp4i-user@ibm.com \
         --upload-file email-files/09c-ace-designer-inst-deploy-success.txt
fi
echo "Done!"