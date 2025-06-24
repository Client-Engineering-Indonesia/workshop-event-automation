#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
echo "Setting Storage Class..."
case "$OCP_TYPE" in
    "ODF")
        OCP_BLOCK_STORAGE='ocs-storagecluster-ceph-rbd'
        OCP_FILE_STORAGE='ocs-storagecluster-cephfs'
        ;;
    "ROKS")
        OCP_BLOCK_STORAGE='ibmc-block-gold'
        OCP_FILE_STORAGE='ibmc-file-gold-gid'
        ;;
    "TZEXT")
        OCP_BLOCK_STORAGE='ocs-external-storagecluster-ceph-rbd'
        OCP_FILE_STORAGE='ocs-external-storagecluster-cephfs'
        ;;
   *)
      echo "Incorrect Storage Class Type. Check Environment Variable OCP_TYPE."
      exit 1
      ;;
esac
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/08-ace-designer-local-ai-instance.yaml ;) | \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
OCP_FILE_STORAGE=${OCP_FILE_STORAGE} \
sh > 08-ace-designer-local-ai-instance.yaml
echo "Deploying ACE Designer instance..."
oc apply -f 08-ace-designer-local-ai-instance.yaml -n tools
echo "Cleaning up temp files..."
rm -f 08-ace-designer-local-ai-instance.yaml
echo "Done! Check progress..."