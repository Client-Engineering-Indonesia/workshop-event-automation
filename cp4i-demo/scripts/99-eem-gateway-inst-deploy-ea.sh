#!/bin/sh
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
EEM_GATEWAY_ROUTE=$(oc get route "${EEM_INST_NAME}-ibm-eem-gateway" -n $EEM_NAMESPACE -o jsonpath="{.spec.host}")
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/common/20x-eem-gateway-ea-instance.yaml ;) | \
    EEM_GATEWAY_ROUTE=${EEM_GATEWAY_ROUTE} \
    sh > temp-eem-gateway-instance.yaml
oc apply -f temp-eem-gateway-instance.yaml
rm -f temp-eem-gateway-instance.yaml