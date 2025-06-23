#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER has been set to " $CP4I_VER
read -p "Press <Enter> to execute script..."
case "$CP4I_VER" in
   "2023.4" | "16.1.0" | "16.1.1")      
      URL=$(oc get routes -n ibm-licensing | grep ibm-licensing-service-instance | awk '{print $2}')
      TKN=$(oc get secret ibm-licensing-token -o jsonpath={.data.token} -n ibm-licensing | base64 -d)
      echo "License Service Version URL: https://"$URL"/version"
      echo "License Service Data Sources URL: https://"$URL"/datasources?token="$TKN
      ;;
   *)
      URL=$(oc get routes -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}')
      TKN=$(oc get secret ibm-licensing-token -o jsonpath={.data.token} -n ibm-common-services | base64 -d)
      ;;
esac
#if [ "$CP4I_VER" = "2023.4" ]
#then
#    URL=$(oc get route ibm-license-service-reporter -n ibm-licensing --no-headers |  awk '{print $2}')
#    TKN=$(oc get secret ibm-license-service-reporter-token -o jsonpath={.data.token} -n ibm-licensing | base64 -D)
#    echo "License Service Version URL: https://"$URL"/version"
#    echo "License Service Data Sources URL: https://"$URL"/datasources?token="$TKN
#else
#    URL=$(oc get routes -n ibm-common-services | grep ibm-licensing-service-instance | awk '{print $2}')
#    TKN=$(oc get secret ibm-licensing-token -o jsonpath={.data.token} -n ibm-common-services | base64 -D)
#    echo "License Service Status Report URL: https://"$URL"/status?token="$TKN
#fi
echo "License Service Status Report URL: https://"$URL"/status?token="$TKN
echo "License Service Snapshot Report URL: https://"$URL"/snapshot?token="$TKN
echo "License Service Products Report URL: https://"$URL"/products?token="$TKN
echo "License Service Bundle Report URL: https://"$URL"/bundled_products?token="$TKN