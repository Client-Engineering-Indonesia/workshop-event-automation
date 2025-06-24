#!/bin/sh
echo "Building SetDBParms Configuration for ES"
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
ES_USER_ID='ace-user'
CONFIG_NAME="ace-es-demo-scram-secid"
CONFIG_TYPE="setdbparms"
CONFIG_NS="tools"
CONFIG_DESCRIPTION="Credentials to connect using SCRAM to ES Demo Cluster"
##########################
# PREPARE CONFIG CONTENT #
##########################
#oc extract secret/${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} --keys=ca.password
#TRUSTSTORE_PWD=`cat ca.password`
TRUSTSTORE_PWD=$(oc get secret ${ES_INST_NAME}-cluster-ca-cert -n ${ES_NAMESPACE} -o=jsonpath='{.data.ca\.password}' | base64 -d)
#oc extract secret/${ES_USER_ID} -n ${ES_NAMESPACE} --keys=password
#ES_USER_PWD=`cat password`
ES_USER_PWD=$(oc get secret ${ES_USER_ID} -n ${ES_NAMESPACE} -o=jsonpath='{.data.password}' | base64 -d)
cat <<EOF >ace-setdbparms-data-es-scram.txt
truststore::truststorePass dummy $TRUSTSTORE_PWD
kafka::esdemoSecId $ES_USER_ID $ES_USER_PWD
EOF
CONFIG_DATA_BASE64=$(base64 -i ace-setdbparms-data-es-scram.txt | tr -d '\n')
########################
# CREATE CONFIGURATION #
########################
( echo "cat <<EOF" ; cat templates/template-ace-config-data.yaml ;) | \
    CONFIG_NAME=${CONFIG_NAME} \
    CONFIG_TYPE=${CONFIG_TYPE} \
    CONFIG_NS=${CONFIG_NS} \
    CONFIG_DESCRIPTION=${CONFIG_DESCRIPTION} \
    CONFIG_DATA_BASE64=${CONFIG_DATA_BASE64} \
    sh > ace-config-setdbparms-es-scram.yaml
echo "Creating ACE Configuration..."
oc apply -f ace-config-setdbparms-es-scram.yaml
oc -n tools label configuration ace-es-demo-scram-secid assembly.integration.ibm.com/tools.jgr-demo=true
echo "Cleaning up temp files..."
#rm -f ca.password
#rm -f password
rm -f ace-setdbparms-data-es-scram.txt
rm -f ace-config-setdbparms-es-scram.yaml
echo "SetDBParms Configuration for ES has been created."
