#!/bin/sh
echo "Configuring Event Streams..."
###################
# INPUT VARIABLES #
###################
ES_INST_NAME='es-demo'
ES_NAMESPACE='tools'
################################
# INITIAL EVENT STREAMS CONFIG #
################################
CLUSTER_ADDRESS='https://'$(oc get route cp-console -n ibm-common-services -o jsonpath='{.status.ingress[0].host}')
ADMIN_PWD=$(oc get secret platform-auth-idp-credentials -n ibm-common-services -o jsonpath='{.data.admin_password}' | base64 --decode)
cloudctl login -a ${CLUSTER_ADDRESS} -u admin -p ${ADMIN_PWD} -n ${ES_NAMESPACE} --skip-ssl-validation
cloudctl es init -n ${ES_NAMESPACE}
cloudctl es topic-create --name cp4i-ivt-topic --partitions 1 --replication-factor 3 --config retention.ms=86400000
cloudctl es topic-create --name cp4i-es-demo-topic --partitions 1 --replication-factor 3 --config retention.ms=86400000
cloudctl es kafka-user-create --name ace-user --consumer --producer --schema-topic-create --all-topics --all-groups --all-txnids --auth-type scram-sha-512
echo "Event Streams has been configured."