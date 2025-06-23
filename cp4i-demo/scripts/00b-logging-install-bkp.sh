#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
b=$(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count } END { print count }')
if [ -z $b ]; then b=0; fi;
let "b+=1"
oc apply -f resources/00a-elasticsearch-namespace.yaml
oc apply -f resources/00b-elasticsearch-operatorgroup.yaml
oc apply -f resources/00c-elasticsearch-subscription.yaml
i=0
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
    while [ $(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $b ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get csv --no-headers -n openshift-operators-redhat | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -ge $b ]
    then
        oc apply -f resources/00d-logging-namespace.yaml
        oc apply -f resources/00e-logging-operatorgroup.yaml
        oc apply -f resources/00f-logging-subscription.yaml
        let "b+=1"
        i=0
        while [ $(oc get csv --no-headers -n openshift-logging | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $b ] && [ $i -lt 5 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for one minute..."
            sleep 60
            let "i++"
        done
        if [ $(oc get csv --no-headers -n openshift-logging | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $b ]
        then
            case "$OCP_TYPE" in
                "ROKS") 
                    oc apply -f resources/00g-logging-instance-roks.yaml
                    ;;
                "ODF") 
                    oc apply -f resources/00g-logging-instance-odf.yaml
                    ;;
            esac
            n=$(oc get nodes | awk '$2=="Ready" { ++count } END { print count }')
            let "n+=5"
            i=0
            while [ $(oc get pods --no-headers -n openshift-logging | awk '$3=="Running" { ++count } END { print count }') -lt $n ] && [ $i -lt 5 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for two minute..."
                sleep 120
                let "i++"
            done
            if [ $(oc get pods --no-headers -n openshift-logging | awk '$3=="Running" { ++count } END { print count }') -ge $n ]
            then
                echo "Logging is Ready."
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files\00b-logging-install-success.txt
                echo "Done!"
                exit
            fi
        fi
    fi
fi
echo "Something is wrong!"
curl --ssl-reqd \
     --url "smtp://smtp.mailtrap.io:2525" \
     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
     --mail-from cp4i-admin@ibm.com \
     --mail-rcpt cp4i-user@ibm.com \
     --upload-file email-files\00b-logging-install-failure.txt
echo "Done!"