#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
ACE_NAMESPACE='tools'
echo "Setting APIC variables..."
if [ -z "$USER_NAME" ]
then
    APIC_CREDENTIALS='apim-credentials-api-key'
    APIC_PROVIDER_ORG='cp4i-demo-org'
else
    APIC_CREDENTIALS='apim-credentials-user-pwd'
    APIC_PROVIDER_ORG='tz-provider-org'
fi
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
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/01-assembly-demo-api-ir.yaml ;) | \
    APIC_CREDENTIALS=${APIC_CREDENTIALS} \
    APIC_PROVIDER_ORG=${APIC_PROVIDER_ORG} \
    OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
    sh > 01-assembly-demo-api-ir.yaml
echo "Deploying Assembly..."
oc apply -f 01-assembly-demo-api-ir.yaml -n ${ACE_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 01-assembly-demo-api-ir.yaml
echo "Done! Check progress..."