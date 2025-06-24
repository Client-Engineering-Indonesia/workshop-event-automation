#!/bin/sh
#if [[ -f artifacts/cp4i-es-demo-topic.yaml ]] && [[ -s artifacts/cp4i-es-demo-topic.yaml ]]; then
#        echo "File exists and larger than zero."
#else
#        echo "File does not exists or has zero bytes."
#fi
#DIRECTORY="../cp4i-ace-artifacts/CP4iQMGRDEMO"
#if [[ -d "${DIRECTORY}" ]]; then
#        if [[ "$(ls -A "${DIRECTORY}")" ]]; then
#                echo "Directory exists and is not empty."
#        else
#                echo "Directory exists but is empty."
#        fi
#else
#        echo "Directory does not exist"
#fi
MQ_CHANNEL="CP4I.ADMIN.SVRCONN"
CHANNEL_SNI=$(echo $MQ_CHANNEL | tr '[:upper:]' '[:lower:]')
OCP_ROUTE="${CHANNEL_SNI//./2e-}.chl.mq.ibm.com"
echo "$OCP_ROUTE"