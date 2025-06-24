#!/bin/sh
echo "Building ACE KEDA Configurations"
if [[ -z "$(oc get configuration github-barauth --no-headers --ignore-not-found -n tools)" ]]
then
    echo "Invoking script to build BARAuth Configuration..."
    scripts/11-ace-config-barauth-github.sh
fi
echo "Building MQ Policy Configuration"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-qmgr-restapi-policy"
CONFIG_TYPE="policyproject"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Policy to connect to REST API Queue Manager"
QMGR_NS="tools"
##########################
# PREPARE CONFIG CONTENT #
##########################
DIRECTORY="../cp4i-ace-artifacts/CP4iQMGRDEMO"
if [[ -d "${DIRECTORY}" ]]
then
    if [[ "$(ls -A "${DIRECTORY}")" ]]
    then
        echo "Packaging Policy..."
        mkdir CP4iQMGRDEMO && cp -a "${DIRECTORY}"/. CP4iQMGRDEMO/
        QMGR_NAME='QMGRRESTAPI'
        QMGR_HOST_NAME='qmgr-rest-api-ibm-mq.'${QMGR_NS}'.svc'
        ( echo "cat <<EOF" ; cat CP4iQMGRDEMO/QMGRDEMO.policyxml ;) | \
            QMGR_NAME=${QMGR_NAME} \
            QMGR_HOST_NAME=${QMGR_HOST_NAME} \
            sh > QMGRDEMO.policyxml
        mv -f QMGRDEMO.policyxml CP4iQMGRDEMO/QMGRDEMO.policyxml
        zip -r CP4iQMGRDEMO.zip CP4iQMGRDEMO
        CONFIG_CONTENT_BASE64=$(base64 -i CP4iQMGRDEMO.zip | tr -d '\n')
        ( echo "cat <<EOF" ; cat templates/template-ace-config-content.yaml ;) | \
        CONFIG_NAME=${CONFIG_NAME} \
        CONFIG_TYPE=${CONFIG_TYPE} \
        CONFIG_NS=${CONFIG_NS} \
        CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
        CONFIG_CONTENT_BASE64=${CONFIG_CONTENT_BASE64} \
        sh > ace-config-policy-mq.yaml
        ########################
        # CREATE CONFIGURATION #
        ########################
        echo "Creating ACE Configuration..."
        oc apply -f ace-config-policy-mq.yaml
        echo "Cleaning up temp files..."
        rm -rf CP4iQMGRDEMO
        rm -f CP4iQMGRDEMO.zip
        rm -f ace-config-policy-mq.yaml
        echo "MQ Policy Configuration has been created."
    else
        echo "Directory ${DIRECTORY} exists but is empty. Check you have not modified the corresponding repo."
    fi
else
    echo "Directory ${DIRECTORY} does not exist. Check you have cloned the corresponding repo."
fi