#!/bin/sh
if [ -z "$EEM_APIC_INT" ]; then echo "EMM is not configured."; exit 1; fi;
echo "Building EEM Policy Configuration"
###################
# INPUT VARIABLES #
###################
EEM_GW_INST_NAME='eem-demo-gw'
EEM_NAMESPACE='tools'
CONFIG_NAME="ace-eem-egw-policy"
CONFIG_TYPE="policyproject"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Policy to connect to Event Endpoint Management Gateway"
##########################
# PREPARE CONFIG CONTENT #
##########################
DIRECTORY="../cp4i-ace-artifacts/CP4IEEMGTWY"
if [[ -d "${DIRECTORY}" ]]
then
    if [[ "$(ls -A "${DIRECTORY}")" ]]
    then
        echo "Packaging Policy..."
        mkdir CP4IEEMGTWY && cp -a "${DIRECTORY}"/. CP4IEEMGTWY/
        #EGW_BOOTSTRAP_SERVER=$(oc get eventgateway ${EEM_GW_INST_NAME} -n ${EEM_NAMESPACE} -o=jsonpath='{range .status.endpoints[*]}{.name}{" "}{.uri}{"\n"}{end}' | awk '$1=="external-route-https" {print $2}' | cut -b 9-)
        EGW_BOOTSTRAP_SERVER=$(oc get eventgateway ${EEM_GW_INST_NAME} -n ${EEM_NAMESPACE} -o=jsonpath='{.status.endpoints[?(@.name=="external-route-https")].uri}' | cut -b 9-)
        EGW_BOOTSTRAP_SERVER=$EGW_BOOTSTRAP_SERVER':443'
        ( echo "cat <<EOF" ; cat CP4IEEMGTWY/eem-gateway.policyxml ;) | \
            EGW_BOOTSTRAP_SERVER=${EGW_BOOTSTRAP_SERVER} \
            sh > eem-gateway.policyxml
        mv -f eem-gateway.policyxml CP4IEEMGTWY/eem-gateway.policyxml
        zip -r CP4IEEMGTWY.zip CP4IEEMGTWY
        CONFIG_CONTENT_BASE64=$(base64 -i CP4IEEMGTWY.zip | tr -d '\n')
        ( echo "cat <<EOF" ; cat templates/template-ace-config-content.yaml ;) | \
            CONFIG_NAME=${CONFIG_NAME} \
            CONFIG_TYPE=${CONFIG_TYPE} \
            CONFIG_NS=${CONFIG_NS} \
            CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
            CONFIG_CONTENT_BASE64=${CONFIG_CONTENT_BASE64} \
            sh > ace-config-policy-eem-gateway.yaml
        ########################
        # CREATE CONFIGURATION #
        ########################
        echo "Creating ACE Configuration..."
        oc apply -f ace-config-policy-eem-gateway.yaml
        echo "Cleaning up temp files..."
        rm -rf CP4IEEMGTWY
        rm -f CP4IEEMGTWY.zip
        rm -f ace-config-policy-eem-gateway.yaml
        echo "EEM Policy Configuration has been created."
    else
        echo "Directory ${DIRECTORY} exists but is empty. Check you have not modified the corresponding repo."
    fi
else
    echo "Directory ${DIRECTORY} does not exist. Check you have cloned the corresponding repo."
fi