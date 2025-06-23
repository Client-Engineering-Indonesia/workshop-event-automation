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
b=$(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }')
if [ -z $b ]; then b=0; fi;
let "b+=9"
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/01-platform-navigator-instance.yaml
i=0
while [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $b ] && [ $i -lt 7 ]
do
    echo "Checking status... " $i
    echo "Sleeping for two minute..."
    sleep 120
    let "i++"
done
if [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $b ]
then
    echo "Something is wrong!"
    curl --ssl-reqd \
         --url "smtp://smtp.mailtrap.io:2525" \
         --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
         --mail-from cp4i-admin@ibm.com \
         --mail-rcpt cp4i-user@ibm.com \
         --upload-file email-files/03a-platform-navigator-inst-deploy-failure.txt
else
    if [ "$CP4I_VER" = "2022.2" ] 
    then
        echo "CP4I v2022.2 path..."
        i=0
        while [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') ] && [ $i -lt 15 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for five minute..."
            sleep 300
            let "i++"
        done
        if [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') ]
        then
            echo "Something is wrong!"
            curl --ssl-reqd \
                 --url "smtp://smtp.mailtrap.io:2525" \
                 --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                 --mail-from cp4i-admin@ibm.com \
                 --mail-rcpt cp4i-user@ibm.com \
                 --upload-file email-files/03a-platform-navigator-inst-deploy-failure.txt
        else
            i=0
            while [ $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') != "True" ] && [ $i -lt 15 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for five minute..."
                sleep 300
                let "i++"
            done
            if [ $(oc get platformnavigator --no-headers -n tools | awk '{print $4}') != "True" ]
            then
                echo "Something is wrong!"
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files/03a-platform-navigator-inst-deploy-failure.txt
            else
                echo "Platform Navigator is Ready."
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files/03a-platform-navigator-inst-deploy-success.txt
            fi
        fi
    else
        echo "CP4I v2022.4 path..."
        i=0
        while [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $5}') ] && [ $i -lt 15 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for five minute..."
            sleep 300
            let "i++"
        done
        if [ -z $(oc get platformnavigator --no-headers -n tools | awk '{print $5}') ]
        then
            echo "Something is wrong!"
            curl --ssl-reqd \
                 --url "smtp://smtp.mailtrap.io:2525" \
                 --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                 --mail-from cp4i-admin@ibm.com \
                 --mail-rcpt cp4i-user@ibm.com \
                 --upload-file email-files/03a-platform-navigator-inst-deploy-failure.txt
        else
            i=0
            while [ $(oc get platformnavigator --no-headers -n tools | awk '{print $5}') != "True" ] && [ $i -lt 15 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for five minute..."
                sleep 300
                let "i++"
            done
            if [ $(oc get platformnavigator --no-headers -n tools | awk '{print $5}') != "True" ]
            then
                echo "Something is wrong!"
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files/03a-platform-navigator-inst-deploy-failure.txt
            else
                echo "Platform Navigator is Ready."
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files/03a-platform-navigator-inst-deploy-success.txt
            fi
        fi
    fi
fi
echo "Done!"