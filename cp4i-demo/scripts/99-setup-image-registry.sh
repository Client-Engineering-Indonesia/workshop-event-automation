#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [[ -z "$(oc get pod -n openshift-image-registry -l docker-registry=default --ignore-not-found --no-headers)" ]]; then
    echo "Image Registry instance is NOT available"
    if [[ "$(oc get clusteroperator image-registry --ignore-not-found --no-headers | awk '{print $3}')" == "True" ]]; then
        echo "Image Registry operator is available"
        echo "Patching Image Registry configuration"
        oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"managementState":"Managed"}}'
        oc patch config.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"Recreate","replicas":1}}'
        echo "Creating PVC for Image Registry"
        oc create -f resources/99-image-registry-pvc.yaml -n openshift-image-registry
        echo "Deploying Image Registry instance"
        oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"storage":{"pvc":{"claim":"image-registry-storage"}}}}'
        while ! oc wait --for=jsonpath='{.status.conditions[1].status}'=True deployment/image-registry -n openshift-image-registry 2>/dev/null; do sleep 30; done
        echo "Image Registry instance is ready"  
    else
        echo "Image Registry operator is NOT available"
    fi
else
    echo "Image Registry instance is available"
fi