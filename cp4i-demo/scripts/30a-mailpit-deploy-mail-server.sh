#!/bin/sh
# This script requires the oc command being installed in your environment
echo "Generating mailpit-admin password..."
MAILPIT_ADMIN_PWD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-')
echo "Preparing mailpit deployment manifest..."
( echo "cat <<EOF" ; cat resources/30a-mailpit-deployment.yaml ;) | \
MAILPIT_ADMIN_PWD=${MAILPIT_ADMIN_PWD} \
sh > mailpit-deployment.yaml
echo "Deploying mailtraip server..."
oc apply -f mailpit-deployment.yaml
echo "Cleaning up temp files..."
rm -f mailpit-deployment.yaml
echo "Password for mailpit-admin is:" ${MAILPIT_ADMIN_PWD}
read -p "Write down the password and then press <Enter> to finish..."
echo "Done! Check progress..."