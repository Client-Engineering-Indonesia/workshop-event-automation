#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$MAILTRAP_USER" ]; then echo "MAILTRAP_USER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$MAILTRAP_PWD" ]; then echo "MAILTRAP_PWD not set, it must be provided on the command line."; exit 1; fi;
echo "MAILTRAP_USER is set to" $MAILTRAP_USER
echo "MAILTRAP_PWD is set to" $MAILTRAP_PWD
read -p "Press <Enter> to execute script..."
b=$(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count } END { print count }')
if [ -z $b ]; then b=0; fi;
let "b+=1"
oc apply -f resources/01a-tracing-platform-namespace.yaml
oc apply -f resources/01b-tracing-platform-operatorgroup.yaml
oc apply -f resources/01c-tracing-platform-subscription.yaml
i=0
while [ -z $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count } END { print count }') ]
then
    i=0
    while [ $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $b ] && [ $i -lt 5 ]
    do
        echo "Checking status... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -ge $b ]
    then
        oc apply -f resources/01d-tracing-data-collection-subscription.yaml
        let "b+=1"
        i=0
        while [ $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count } END { print count }') -lt $b ] && [ $i -lt 5 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for one minute..."
            sleep 60
            let "i++"
        done
        if [ $(oc get csv --no-headers -n openshift-distributed-tracing | awk '$(NF)=="Succeeded" { ++count } END { print count }') -ge $b ]
        then
            oc apply -f resources/01e-tracing-instance.yaml
            i=0
            while [ -z $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '{print $2}') ] && [ $i -lt 10 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for one minute..."
                sleep 60
                let "i++"
            done
            if [ ! -z $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '{print $2}') ]
            then
                i=0
                while [ $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '{print $2}') != "Running" ] && [ $i -lt 10 ]
                do
                    echo "Checking status... " $i
                    echo "Sleeping for one minute..."
                    sleep 60
                    let "i++"
                done
                if [ $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '{print $2}') = "Running" ]
                then
                    echo "Tracing is Ready."
                    curl --ssl-reqd \
                         --url "smtp://smtp.mailtrap.io:2525" \
                         --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                         --mail-from cp4i-admin@ibm.com \
                         --mail-rcpt cp4i-user@ibm.com \
                         --upload-file - <<EOF
From: CP4I Admin <cp4i-admin@ibm.com>
To: Mailtrap Inbox <cp4i-user@ibm.com>
Subject: Tracing has been deployed!
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Congrats Tracing has been deployed.

Inspect it using the commands provided in the repo.
Now you can proceed to apply your entitlement key.

Good luck! 

--boundary-string
EOF
                    echo "Done!"
                    exit
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
     --upload-file - <<EOF
From: CP4I Admin <cp4i-admin@ibm.com>
To: Mailtrap Inbox <cp4i-user@ibm.com>
Subject: Tracing hasn't been fully installed!
Content-Type: multipart/alternative; boundary="boundary-string"

--boundary-string
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline

Something is wrong!

Inspect the Tracing instance status.
Take corrective actions to complete the installation.

Good luck! 

--boundary-string
EOF
echo "Done!"