#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
b=$(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }')
if [ -z $b ]; then b=0; fi;
loo=$b
lics=$b
oc apply -f subscriptions/${CP4I_VER}/01-platform-navigator-subscription.yaml
i=0
while [ -z $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') ]
then
    let "loo+=2"
    i=0
    while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $loo ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -ge $loo ]
    then
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
            let "lics+=4"
            i=0
            while [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $lics ] && [ $i -lt 5 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for one minute..."
                sleep 60
                let "i++"
            done
            if [ $(oc get csv --no-headers -n ibm-common-services | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $lics ]
            then
                oc apply -f subscriptions/${CP4I_VER}/02-asset-repo-subscription.yaml
                let "loo+=1"
                i=0
                while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                do
                    echo "Checking status... " $i
                    echo "Sleeping for two minute..."
                    sleep 120
                    let "i++"
                done
                if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                then
                    case "$CP4I_VER" in
                        "2022"*) 
                            oc apply -f subscriptions/${CP4I_VER}/03-operations-dashboard-subscription.yaml
                            let "loo+=1"
                            i=0
                            while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                            do
                                echo "Checking status... " $i
                                echo "Sleeping for two minute..."
                                sleep 120
                                let "i++"
                            done
                            ;;
                    esac
                    if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                    then
                        oc apply -f subscriptions/${CP4I_VER}/04-api-connect-subscription.yaml
                        let "loo+=2"
                        i=0
                        while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                        do
                            echo "Checking status... " $i
                            echo "Sleeping for two minute..."
                            sleep 120
                            let "i++"
                        done
                        if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                        then
                            oc apply -f subscriptions/${CP4I_VER}/05-event-streams-subscription.yaml
                            let "loo+=1"
                            i=0
                            while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                            do
                                echo "Checking status... " $i
                                echo "Sleeping for two minute..."
                                sleep 120
                                let "i++"
                            done
                            if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                            then
                                oc apply -f subscriptions/${CP4I_VER}/06-mq-subscription.yaml
                                let "loo+=1"
                                i=0
                                while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                do
                                    echo "Checking status... " $i
                                    echo "Sleeping for two minute..."
                                    sleep 120
                                    let "i++"
                                done
                                if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                then
                                    oc apply -f subscriptions/${CP4I_VER}/07-app-connect-subscription.yaml
                                    let "loo+=1"
                                    i=0
                                    while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                    do
                                        echo "Checking status... " $i
                                        echo "Sleeping for two minute..."
                                        sleep 120
                                        let "i++"
                                    done
                                    if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                    then
                                        oc apply -f subscriptions/${CP4I_VER}/08-aspera-hsts-subscription.yaml
                                        let "loo+=2"
                                        i=0
                                        while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                        do
                                            echo "Checking status... " $i
                                            echo "Sleeping for two minute..."
                                            sleep 120
                                            let "i++"
                                        done
                                        if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                        then
                                            case "$CP4I_VER" in
                                                "2023"*)
                                                    oc apply -f subscriptions/${CP4I_VER}/09-eem-subscription.yaml
                                                    let "loo+=1"
                                                    i=0
                                                    while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                                    do
                                                        echo "Checking status... " $i
                                                        echo "Sleeping for two minute..."
                                                        sleep 120
                                                        let "i++"
                                                    done
                                                    if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                                    then
                                                        oc apply -f subscriptions/${CP4I_VER}/10-ea-flink-subscription.yaml
                                                        let "loo+=1"
                                                        i=0
                                                        while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                                        do
                                                            echo "Checking status... " $i
                                                            echo "Sleeping for two minute..."
                                                            sleep 120
                                                            let "i++"
                                                        done
                                                        if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                                        then
                                                            oc apply -f subscriptions/${CP4I_VER}/11-event-processing-subscription.yaml
                                                            let "loo+=1"
                                                            i=0
                                                            while [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $loo ] && [ $i -lt 5 ]
                                                            do
                                                                echo "Checking status... " $i
                                                                echo "Sleeping for two minute..."
                                                                sleep 120
                                                                let "i++"
                                                            done
                                                        fi
                                                    fi
                                                    ;;
                                            esac
                                            if [ $(oc get csv --no-headers -n openshift-operators | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $loo ]
                                            then 
                                                echo "CP4I Subscriptios are Ready."
                                                curl --ssl-reqd \
                                                     --url "smtp://smtp.mailtrap.io:2525" \
                                                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                                                     --mail-from cp4i-admin@ibm.com \
                                                     --mail-rcpt cp4i-user@ibm.com \
                                                     --upload-file email-files/02b-cp4i-apply-subscriptions-success.txt
                                                echo "Done!"
                                                exit
                                            fi
                                        fi
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
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
     --upload-file email-files/02b-cp4i-apply-subscriptions-failure.txt
echo "Done!"