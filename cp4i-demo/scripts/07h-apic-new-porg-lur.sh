#!/bin/sh
# This script requires the oc command being installed in your environment
# This script requires the apic command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo "apic could not be found"; exit 1; fi;
echo "Creating new Provider Organization..."
###################
# INPUT VARIABLES #
###################
APIC_INST_NAME='apim-demo'
APIC_NAMESPACE='tools'
######################
# SET APIC VARIABLES #
######################
#PORG_NAME='user-demo-org'
#PORG_TITLE='USER Demo Provider Org'
PORG_NAME='tz-provider-org'
PORG_TITLE='TechZone Provider Organization'
APIC_REALM='admin/default-idp-1'
APIC_ADMIN_USER='admin'
APIC_ADMIN_ORG='admin'
APIC_USER_REGISTRY='api-manager-lur'
APIC_MGMT_SERVER=$(oc get route "${APIC_INST_NAME}-mgmt-platform-api" -n $APIC_NAMESPACE -o jsonpath="{.spec.host}")
APIC_ADMIN_PWD=$(oc get secret "${APIC_INST_NAME}-mgmt-admin-pass" -n $APIC_NAMESPACE -o jsonpath="{.data.password}"| base64 -d)
#################
# LOGIN TO APIC #
#################
echo "Login to APIC with CMC Admin User..."
apic login --server $APIC_MGMT_SERVER --realm $APIC_REALM -u $APIC_ADMIN_USER -p $APIC_ADMIN_PWD
##########################
# CREATE NEW USER IN LUR #
##########################
echo "Preparing User File for user " $USER_NAME
( echo "cat <<EOF" ; cat templates/template-apic-user.yaml ;) | \
    USER_NAME=${USER_NAME} \
    USER_EMAIL=${USER_EMAIL} \
    USER_FNAME=${USER_FNAME} \
    USER_LNAME=${USER_LNAME} \
    USER_PWD=${USER_PWD} \
    sh > apic-user.yaml
echo "Creating User in LUR..."
USER_URL=$(apic users:create --server $APIC_MGMT_SERVER --org $APIC_ADMIN_ORG --user-registry $APIC_USER_REGISTRY apic-user.yaml | awk '{print $4}')
###########################
# CREATE NEW PROVIDER ORG #
###########################
echo "Preparing POrg File for Organization " $PORG_NAME
( echo "cat <<EOF" ; cat templates/template-apic-provider-org.yaml ;) | \
    PORG_NAME=${PORG_NAME} \
    PORG_TITLE=${PORG_TITLE} \
    USER_URL=${USER_URL} \
    sh > provider-org.yaml
echo "Creating Provider Organization " $PORG_NAME
apic orgs:create --server $APIC_MGMT_SERVER provider-org.yaml
echo "Cleaning up temp files..."
rm -f apic-user.yaml
rm -f provider-org.yaml
echo "Provider Organization has been created."