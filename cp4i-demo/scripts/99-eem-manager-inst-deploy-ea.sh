#!/bin/sh
# This script requires the oc command being installed in your environment
# Before running the script you need to set two environment variables called "EEM_ADMIN_PWD" and "ES_USER_PWD" with your maintrap info, using these command: 
# "export EEM_ADMIN_PWD=my-eem-admin-pwd"
# "export ES_USER_PWD=my-es-user-pwd"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ]; then echo "This script is for CP4I v16.1.0"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
echo "Deploying EEM Manager..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/19x-eem-manager-local-ea-instance.yaml
echo "Done! Check progress..."
