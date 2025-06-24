#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
#if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1")
      ;;
   *)
      echo "This script is for CP4I v2023.4 or v16.1.*"
      exit 1
      ;;
esac
#if [ "$CP4I_VER" != "2023.4" ]; then echo "This script is for CP4I v2023.4"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
echo "Configuting Data Source for License Reporter..."
REPORTER_URL=$(oc get route ibm-license-service-reporter -n ibm-licensing -o jsonpath={.spec.host})
REPORTER_URL="https://"$REPORTER_URL
oc get ibmlicensing instance -n ibm-licensing -o json > instance.json
jq --arg REPORTER_URL $REPORTER_URL \
     '.spec.sender += {"reporterSecretToken":"ibm-license-service-reporter-token"} |
      .spec.sender += {"reporterURL":($REPORTER_URL)}' \
     instance.json > instance-updated.json
oc apply -f instance-updated.json
rm -f instance.json
rm -f instance-updated.json
echo "Done!"