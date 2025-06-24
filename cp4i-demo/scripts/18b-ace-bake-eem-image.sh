#!/bin/sh
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$EEM_APIC_INT" ]; then echo "EMM is not configured."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
echo "Building Custom ACE Image"
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
CONFIG_NAME="egw-cert.jks"
CONFIG_TYPE="truststore"
CONFIG_DESCRIPTION="JKS certificate for Event Endpoint Management Gateway"
CONFIG_NS="tools"
########################
# CREATE CONFIGURATION #
########################
#
echo "Override original BAR file..."
ASYNCAPI_CID=$(jq -r '."x-ibm-configuration".assembly.execute[0]."invoke-kafka".clusterconfigid' "artifacts/cp4i-es-demo-topic_1.0.0.json")
cat <<EOF >eemOverridesFile
SendEmail#KafkaConsumer.clientId=$ASYNCAPI_CID
EOF
source '/Applications/IBM App Connect Enterprise.app/Contents/mqsi/server/bin/mqsiprofile'
ibmint apply overrides 'eemOverridesFile' --input-bar-file 'resources/07-jgr-cp4i-kafka2mail.bar' --output-bar-file 'jgr-cp4i-kafka2mail.bar'
#
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
sleep 10
HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
podman login cp.icr.io -u cp -p $ENT_KEY
case $CP4I_VER in
    2022.2 )
        IMG_VER="12.0.6.0-r2-lts"
        podman pull cp.icr.io/cp/appc/ace-server-prod@sha256:1f8e0d52d5ffb68232c9b6aa361bd1abe6617ef290469c3d99a0a67fc2cdc1bd
        ;;
    2022.4 )
        IMG_VER="12.0.7.0-r2"
        podman pull cp.icr.io/cp/appc/ace-server-prod@sha256:9b679f0b1784d04e23796c25894763b26546b0966c93f82b504a260370e2be35
        ;;
    2023.4 )
        IMG_VER="12.0.10.0-r3"
        podman pull cp.icr.io/cp/appc/ace-server-prod@sha256:92692cc01452f9cbe5075c737b850833516bccf7845f2f40c9bfdd160edbaa38
esac
IMG_NAME="cp.icr.io/cp/appc/ace-server-prod"
IMG_ID=$(podman images | awk -v img_name=$IMG_NAME '$1 == img_name {print $3}')
podman tag $IMG_ID $IMG_NAME:$IMG_VER
#
cp extras/ACE-IS-Dockerfile Dockerfile
podman build -t $HOST/tools/ace-${IMG_VER}-kafka2email:1.0.0 --build-arg ACEVER=${IMG_VER} .
OCP_USER=$(oc whoami)
if [ "$OCP_USER" = "kube:admin" ]; then OCP_USER='kubeadmin'; fi
podman login -u $OCP_USER -p $(oc whoami -t) $HOST
podman push $HOST/tools/ace-${IMG_VER}-kafka2email:1.0.0
#
echo "Cleaning up temp files..."
rm -f Dockerfile
rm -f eemOverridesFile
rm -f jgr-cp4i-kafka2mail.bar
echo "ACE Image has been built."