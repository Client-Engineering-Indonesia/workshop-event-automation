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
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/30-qmgr-ext-np-nosni.yaml ;) | \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
MQ_VERSION=${MQ_VERSION} \
sh > 30-qmgr-ext-np-nosni.yaml
echo "Deploying Queue Manager instance..."
oc apply -f 30-qmgr-ext-np-nosni.yaml -n tools
oc apply -f resources/03f-qmgr-service-nodeport.yaml -n tools
echo "Cleaning up temp files..."
rm -f 30-qmgr-ext-np-nosni.yaml
echo "Done! Check progress..."