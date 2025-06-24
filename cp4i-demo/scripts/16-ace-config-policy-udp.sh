#!/bin/sh
echo "Building User Defined Policy Configuration"
###################
# INPUT VARIABLES #
###################
CONFIG_NAME="ace-cp4i-demo-policy"
CONFIG_TYPE="policyproject"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Policy to configure default values for CP4I Demo"
##########################
# PREPARE CONFIG CONTENT #
##########################
DIRECTORY="../cp4i-ace-artifacts/CP4IDEMO"
if [[ -d "${DIRECTORY}" ]]
then
    if [[ "$(ls -A "${DIRECTORY}")" ]]
    then
        echo "Packaging Policy..."
        mkdir CP4IDEMO && cp -a "${DIRECTORY}"/. CP4IDEMO/
        zip -r CP4IDEMO.zip CP4IDEMO
        CONFIG_CONTENT_BASE64=$(base64 -i CP4IDEMO.zip | tr -d '\n')
        ( echo "cat <<EOF" ; cat templates/template-ace-config-content.yaml ;) | \
            CONFIG_NAME=${CONFIG_NAME} \
            CONFIG_TYPE=${CONFIG_TYPE} \
            CONFIG_NS=${CONFIG_NS} \
            CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
            CONFIG_CONTENT_BASE64=${CONFIG_CONTENT_BASE64} \
            sh > ace-config-policy-udp.yaml
        ########################
        # CREATE CONFIGURATION #
        ########################
        echo "Creating ACE Configuration..."
        oc apply -f ace-config-policy-udp.yaml
        oc -n tools label configuration ace-cp4i-demo-policy assembly.integration.ibm.com/tools.jgr-demo=true
        echo "Cleaning up temp files..."
        rm -rf CP4IDEMO
        rm -f CP4IDEMO.zip
        rm -f ace-config-policy-udp.yaml
        echo "User Defined Policy Configuration has been created."
    else
        echo "Directory ${DIRECTORY} exists but is empty. Check you have not modified the corresponding repo."
    fi
else
    echo "Directory ${DIRECTORY} does not exist. Check you have cloned the corresponding repo."
fi