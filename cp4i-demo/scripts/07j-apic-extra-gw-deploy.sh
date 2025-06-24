#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo "yq could not be found"; exit 1; fi;
echo "Deploying extra API Gateway..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
DP_NAMESPACE='cp4i-dp'
############################
# DEPLOY EXTRA API GATEWAY #
############################
echo "Preparing APIC ingress CA..."
oc -n tools get secret "${APIC_INST_NAME}-ingress-ca" -o yaml > ingress-ca.yaml
yq -i 'del(.metadata.creationTimestamp, .metadata.namespace, .metadata.resourceVersion, .metadata.uid, .metadata.selfLink)' \
        ingress-ca.yaml
oc apply -f ingress-ca.yaml -n ${DP_NAMESPACE}
echo "Defining resources..."
oc apply -f resources/13a-apic-dp-selfsigning-issuer.yaml -n ${DP_NAMESPACE}
oc apply -f resources/13b-apic-dp-ingress-issuer.yaml -n ${DP_NAMESPACE}
oc apply -f resources/13c-apic-dp-gw-service-certificate.yaml -n ${DP_NAMESPACE}
oc apply -f resources/13d-apic-dp-gw-peering-certificate.yaml -n ${DP_NAMESPACE}
oc -n ${DP_NAMESPACE} create secret generic admin-secret --from-literal=password=admin
echo "Preparing YAML file..."
STACK_HOST=$(oc get route "${APIC_INST_NAME}-gw-gateway" -n ${APIC_NAMESPACE} -o jsonpath="{.spec.host}" | cut -d'.' -f2-)
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/23-apic-api-gwy-instance.yaml ;) | \
    STACK_HOST=${STACK_HOST} \
    sh > temp-apic-api-gwy-instance.yaml
echo "Creating API Gateway instance..."
oc apply -f temp-apic-api-gwy-instance.yaml -n ${DP_NAMESPACE}
#echo "Preparing Route file..."
#( echo "cat <<EOF" ; cat templates/template-dp-route.yaml ;) | \
#    STACK_HOST=${STACK_HOST} \
#    sh > dp-route.yaml
#echo "Creating API Gateway route..."
#oc apply -f dp-route.yaml -n ${DP_NAMESPACE}
echo "Cleaning up temp files..."
rm -f temp-apic-api-gwy-instance.yaml
rm -f ingress-ca.yaml
#rm -f dp-route.yaml
echo "API Gateway has been deployed."
