#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the yq utility being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo "yq could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
##################
# INPUT VARIABLE #
##################
MQ_USER_ID='mq-admin'
echo "Generating mq-admin password..."
MQ_USER_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
case "$CP4I_VER" in
    "16.1.0")
        MQ_VERSION='9.4.0.11-r2'
        ;;
    "16.1.1")
        MQ_VERSION='9.4.2.1-r2'
esac
echo "Setting Storage Class..."
case "$OCP_TYPE" in
    "ODF")
        OCP_BLOCK_STORAGE='ocs-storagecluster-ceph-rbd'
        ;;
    "ROKS")
        OCP_BLOCK_STORAGE='ibmc-block-gold'
        ;;
    "TZEXT")
        OCP_BLOCK_STORAGE='ocs-external-storagecluster-ceph-rbd'
        ;;
   *)
      echo "Incorrect Storage Class Type. Check Environment Variable OCP_TYPE."
      exit 1
      ;;
esac
echo "Preparing mqweb ConfigMap..."
( echo "cat <<EOF" ; cat templates/template-mq-web-config.yaml ;) | \
MQ_USER_ID=${MQ_USER_ID} \
MQ_USER_PWD=${MQ_USER_PWD} \
sh > mq-web-config.yaml
echo "Creating mqweb ConfigMap..."
oc apply -f mq-web-config.yaml -n tools
echo "Preparing MQ Secret for KEDA..."
oc extract secret/qmgr-rest-api-tls-secret -n tools --keys=tls.crt
oc extract secret/qmgr-rest-api-tls-secret -n tools --keys=tls.key
echo "Creating MQ Secret..."
oc create secret -n tools generic keda-mq-secret \
    --from-literal=ADMIN_USER="${MQ_USER_ID}" \
    --from-literal=ADMIN_PASSWORD="${MQ_USER_PWD}" \
    --from-file=cert=tls.crt \
    --from-file=key=tls.key
if [[ -z "$(oc get configmap mq-demo-mqsc -n tools --ignore-not-found --no-headers)" ]]
then
    oc apply -f resources/03c-qmgr-mqsc-config.yaml -n tools
fi
echo "Preparing queue manager deployment manifest..."
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/31-qmgr-rest-api.yaml ;) | \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
MQ_VERSION=${MQ_VERSION} \
sh > 31-qmgr-rest-api.yaml
echo "Deploying Queue Manager instance..."
oc apply -f 31-qmgr-rest-api.yaml -n tools
echo "Cleaning up temp files..."
rm -f mq-web-config.yaml
#rm -f mq-keda-secret.yaml
rm -f tls.crt
rm -f tls.key
rm -f 31-qmgr-rest-api.yaml
echo "Password for mq-admin is:" ${MQ_USER_PWD}
read -p "Write down the password and then press <Enter> to finish..."
echo "Done! Check progress..."