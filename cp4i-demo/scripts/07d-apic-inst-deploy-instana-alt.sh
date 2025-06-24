#!/bin/sh
# This script requires the oc command being installed in your environment
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
case "$CP4I_VER" in
   "2023.4" | "16.1.0")
      ;;
   *)
      echo "This script is for CP4I v2023.4 or v16.1.0"
      exit 1
      ;;
esac
echo "OCP_TYPE is set to" $OCP_TYPE
if [ -z "$CP4I_TRACING" ]; then echo "CP4I Tracing is NOT enabled"; else echo "CP4I Tracing is enabled"; fi;
read -p "Press <Enter> to execute script..."
if [ -z "$CP4I_TRACING" ]
then
    echo "Deploying APIC instance without tracing..."
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/04-apic-emm-hpa-test-billing-instance.yaml
else
    echo "Deploying APIC instance with tracing enabled..."
    oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/tracing/04-apic-emm-tracing-hpa-test-billing-instance.yaml
fi
echo "Done!"