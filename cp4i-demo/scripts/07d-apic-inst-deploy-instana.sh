#!/bin/sh
# This script requires the oc command being installed in your environment
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
read -p "Press <Enter> to execute script..."
APIC_NAMESPACE='tools'
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
( echo "cat <<EOF" ; cat instances/${CP4I_VER}/04-apic-emm-hpa-test-billing-instance.yaml ;) | \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
sh > 04-apic-emm-hpa-test-billing-instance.yaml
if [ ! -z "$CP4I_TRACING" ]
then
    echo "Configuring Tracing for APIC instance..."
    echo "Work in progress..."
fi
echo "Deploying APIC instance..."
oc apply -f 04-apic-emm-hpa-test-billing-instance.yaml -n ${APIC_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 04-apic-emm-hpa-test-billing-instance.yaml
echo "Done! Check progress..."