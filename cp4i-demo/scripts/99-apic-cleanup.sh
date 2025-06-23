#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
######################
# SET APIC VARIABLES #
######################
APIC_INST_NAME='apic-demo'
APIC_NAMESPACE='cp4i'
echo "Cleaning up APIC instance deployment..."
echo "Deleting PVCs..."
#oc get pvc --no-headers -n $APIC_NAMESPACE | awk -v apicinstname="${APIC_INST_NAME}" '$1 ~ apicinstname {print $1}'
oc get pvc --no-headers -n $APIC_NAMESPACE | awk -v apicinstname="${APIC_INST_NAME}" '$1 ~ apicinstname { system("oc delete pvc " $1) }'
echo "Deleting Secrets..."
#oc get secret --no-headers -n $APIC_NAMESPACE | awk -v apicinstname="${APIC_INST_NAME}" '$1 ~ apicinstname {print $1}'
oc get secret --no-headers -n $APIC_NAMESPACE | awk -v apicinstname="${APIC_INST_NAME}" '$1 ~ apicinstname { system("oc delete secret " $1) }'
echo "Done!"