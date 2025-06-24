#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1")
      ;;
   *)
      echo "This script is for CP4I v2023.4 or v16.1.*"
      exit 1
      ;;
esac
#if [ "$CP4I_VER" != "2023.4" ]; then echo "This script is for CP4I v2023.4"; exit 1; fi;
LSR_HOST=$(oc get route ibm-lsr-console -n ibm-licensing -o jsonpath={.spec.host})
LSR_PATH=$(oc get route ibm-lsr-console -n ibm-licensing -o jsonpath={.spec.path})
LSR_USER_NAME=$(oc get secret ibm-license-service-reporter-credentials -o jsonpath={.data.username} -n ibm-licensing | base64 -D)
LSR_USER_PWD=$(oc get secret ibm-license-service-reporter-credentials -o jsonpath={.data.password} -n ibm-licensing | base64 -D)
echo "License Service Reporter Dashboard URL: https://"$LSR_HOST$LSR_PATH
echo "License Service Reporter User: " $LSR_USER_NAME
echo "License Service Reporter Password: " $LSR_USER_PWD