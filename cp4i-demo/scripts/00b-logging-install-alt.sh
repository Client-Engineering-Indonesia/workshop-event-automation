#!/bin/sh
# This script requires the oc command being installed in your environment 
# Before running the script you need to set two environment variables called "MAILTRAP_USER" and "MAILTRAP_PWD" with your maintrap info, using these command: 
# "export MAILTRAP_USER=my-mailtrap-user"
# "export MAILTRAP_PWD=my-mailtrap-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
echo "Deploying Logging instance..."
case "$OCP_TYPE" in
    "ROKS") 
        oc apply -f resources/00g-logging-instance-roks.yaml
        ;;
    "ODF") 
        oc apply -f resources/00g-logging-instance-odf.yaml
        ;;
    "TZEXT") 
        oc apply -f resources/00g-logging-instance-tzext.yaml
        ;;
esac
echo "Done! Check progress..."