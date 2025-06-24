#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set five environment variables called "ZONE_NAME", "CLUSTER_NAME", "INSTANA_APP_KEY, "INSTANA_SVC_ENDPOINT", "INSTANA_SVC_PORT"
# based on the information you gather from the Instana environment you will be connecting to, using these command: 
# "export ZONE_NAME=<my-zone-name>"
# "export CLUSTER_NAME=<my-cluster-name>"
# "export INSTANA_APP_KEY=<instana-app-key>"
# "export INSTANA_SVC_ENDPOINT=<instana-service-endpoint>"
# "export INSTANA_SVC_PORT=<instana-service-port>"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! -z "$CP4I_TRACING" ]; then echo "Tracing is disabled."; exit; fi;
#if [ -z $(oc get jaeger --no-headers jaeger-all-in-one-inmemory -n openshift-distributed-tracing | awk '$2=="Running" { ++count } END { print count }') ]; then echo "Jaegar instance is NOT running. Check tracing installation."; exit 1; fi; 
if [ -z "$ZONE_NAME" ]; then echo "ZONE_NAME not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$CLUSTER_NAME" ]; then echo "CLUSTER_NAME not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_APP_KEY" ]; then echo "INSTANA_APP_KEY not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_SVC_ENDPOINT" ]; then echo "INSTANA_SVC_ENDPOINT not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$INSTANA_SVC_PORT" ]; then echo "INSTANA_SVC_PORT not set, it must be provided on the command line."; exit 1; fi;
echo "ZONE_NAME is set to" $ZONE_NAME
echo "CLUSTER_NAME is set to" $CLUSTER_NAME
echo "INSTANA_APP_KEY is set to" $INSTANA_APP_KEY
echo "INSTANA_SVC_ENDPOINT is set to" $INSTANA_SVC_ENDPOINT
echo "INSTANA_SVC_PORT is set to" $INSTANA_SVC_PORT
read -p "Press <Enter> to execute script..."
echo "Installing Instana dependencies..."
oc new-project instana-agent
oc adm policy add-scc-to-user privileged -z instana-agent -n instana-agent
#b=$(oc get csv --no-headers -n instana-agent | awk '$(NF)=="Succeeded" { ++count } END { print count }')
#if [ -z $b ]; then b=0; fi;
#let "b+=1"
b=0
oc apply -f resources/01f-instana-agent-subscription.yaml
i=0
echo "Waiting for the Instana dependencies to get ready..."
while [ -z $(oc get csv --no-headers -n instana-agent | grep instana-agent | awk '$(NF)=="Succeeded" { ++count } END { print count }') ] && [ $i -lt 5 ]
do
    echo "Checking status init... " $i
    echo "Sleeping for one minute..."
    sleep 60
    let "i++"
done
if [ ! -z $(oc get csv --no-headers -n instana-agent | grep instana-agent | awk '$(NF)=="Succeeded" { ++count } END { print count }') ]
then
    i=0
    while [ $(oc get csv --no-headers -n instana-agent | grep instana-agent | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -lt $b ] && [ $i -lt 5 ]
    do
        echo "Checking status deploy... " $i
        echo "Sleeping for one minute..."
        sleep 60
        let "i++"
    done
    if [ $(oc get csv --no-headers -n instana-agent | grep instana-agent | awk '$(NF)=="Succeeded" { ++count1 } END { print count1 }') -ge $b ]
    then
        #########################
        # CREATE AGENT INSTANCE #
        #########################
        echo "Creating Instana Agent instance..."
        (echo "cat <<EOF" ; cat templates/template-instana-agent.yaml ;) | \
            ZONE_NAME=${ZONE_NAME} \
            CLUSTER_NAME=${CLUSTER_NAME} \
            INSTANA_APP_KEY=${INSTANA_APP_KEY} \
            INSTANA_SVC_ENDPOINT=${INSTANA_SVC_ENDPOINT} \
            INSTANA_SVC_PORT=${INSTANA_SVC_PORT} \
            sh > instana-agent.yaml
        oc apply -f instana-agent.yaml
        n=$(oc get nodes | awk '($2=="Ready" && $3=="worker") { ++count } END { print count }')
        i=0
        echo "Waiting for Instana Agent instance to get ready..."
        while [ -z $(oc get pods --no-headers -n instana-agent | awk '$3=="Running" { ++count } END { print count }') ] && [ $i -lt 5 ]
        do
            echo "Checking status... " $i
            echo "Sleeping for one minute..."
            sleep 60
            let "i++"
        done
        echo "Cleaning up temp files..."
        rm -f instana-agent.yaml
        if [ ! -z $(oc get pods --no-headers -n instana-agent | awk '$3=="Running" { ++count } END { print count }') ]
        then
            i=0
            while [ $(oc get pods --no-headers -n instana-agent | awk '$3=="Running" { ++count } END { print count }') -lt $n ] && [ $i -lt 5 ]
            do
                echo "Checking status... " $i
                echo "Sleeping for two minute..."
                sleep 120
                let "i++"
            done        
            if [ $(oc get pods --no-headers -n instana-agent | awk '$3=="Running" { ++count } END { print count }') -ge $n ]
            then        
                echo "Instana Agent has been deployed."
                curl --ssl-reqd \
                     --url "smtp://smtp.mailtrap.io:2525" \
                     --user "${MAILTRAP_USER}:${MAILTRAP_PWD}" \
                     --mail-from cp4i-admin@ibm.com \
                     --mail-rcpt cp4i-user@ibm.com \
                     --upload-file email-files/01b-instana-install-success.txt
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
     --upload-file email-files/01b-instana-install-failure.txt
echo "Done!"