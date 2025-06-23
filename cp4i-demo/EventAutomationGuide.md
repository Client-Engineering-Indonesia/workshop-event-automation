# IBM Event Automation installation instructions

This repository provides assets to deploy the full CP4I stack plus Event Automation (aka EA), but if you are only interested in EA you can use this simplified guide.

Note this guide will give you the foundation to follow the EA tutorials available in the [documentation](https://ibm.github.io/event-automation/tutorials/). I keep these assets in sync with the main EA Demo Repo located [here](https://github.com/IBM/event-automation-demo), just keep in mind there is always a few weeks lag, so if you need the latest and grates version use the intsructions in the other repo. And this guide is useful for situations where you have issues with Ansible.

<details>
<summary>
A) Set environment variables:
</summary>

1. Set the CP4I version to the latest LTS versions to get the latest version of EA, so use the following command:
    ```
    export CP4I_VER=16.1.0
    ```
2. Set the OCP type based on the storage classes in your cluster:
   ```
   export OCP_TYPE=ROKS
   or 
   export OCP_TYPE=ODF

</details>
&nbsp; 

<details>
<summary>
B) Set a default storage class for your cluster:
</summary>

1. If you have provisioned your OCP cluster in Tech Zone you can use the following script to set the proper default storage class:
   ```
   scripts/99-odf-tkz-set-scs.sh
   ```
</details>
&nbsp; 

<details>
<summary>
C) Install Event Automation pre-requisites:
</summary>   

1. Install Cert Manager Operator:
   ```
   oc apply -f resources/00-cert-manager-namespace.yaml
   oc apply -f resources/00-cert-manager-operatorgroup.yaml
   oc apply -f resources/00-cert-manager-subscription.yaml
   ```
   Confirm the subscription has been completed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment cert-manager-operator-controller-manager -n cert-manager-operator --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME -n cert-manager-operator --ignore-not-found -o jsonpath='{.status.phase}';fi;echo
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
</details>
&nbsp; 

<details>
<summary>
D) Create namespaces with the corresponding entitlement key:
</summary>

1. Set your entitlement key:
   ```
   export ENT_KEY=<my-key>
   ```
2. Create namespaces:
   ```
   scripts/02a-cp4i-ns-key-config.sh
   ```
</details>
&nbsp; 

<details>
<summary>
E) Deploy Event Streams: 
</summary>

1. Install Event Streams Catalog Source:
   ```
   oc apply -f catalog-sources/${CP4I_VER}/08-event-streams-catalog-source.yaml
   ```
   Confirm the catalog source has been deployed successfully before moving to the next step running the following command: 
   ```
   oc get catalogsources ibm-eventstreams-catalog -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState}';echo
   ```
   You should get a response like this:
   ```
   READY
   ```
2. Install Event Streams Operator:
   ```
   oc apply -f subscriptions/${CP4I_VER}/05-event-streams-subscription.yaml
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment eventstreams-cluster-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME --ignore-not-found -o jsonpath='{.status.phase}';fi;echo 
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
3. Deploy Event Streams instance:
   ```
   oc apply -f instances/${CP4I_VER}/${OCP_TYPE}/05x-event-streams-ea-instance.yaml
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventstreams es-demo -n tools -o jsonpath='{.status.phase}';echo
   ```
   Note this will take few minutes, so be patient, and at some point you may see some errors, but at the end you should get a response like this:
   ```
   Ready
   ```
4. Create topics and users:
   ```
   oc apply -f resources/02a-es-initial-config-jgr-topics.yaml -n tools
   oc apply -f resources/02a-es-initial-config-jgr-users.yaml -n tools
   oc apply -f resources/02a-es-initial-config-ea-topics.yaml -n tools
   oc apply -f resources/02a-es-initial-config-watsonx-topics.yaml -n tools
   ```
5. Enable Kafka Connect base:
   ```
   scripts/08c-event-streams-kafka-connect-config.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get kafkaconnects jgr-connect-cluster -n tools -o jsonpath='{.status.conditions[0].type}';echo
   ```
   Note this will take few minutes, but at the end you should get a response like this:
   ```
   Ready
   ```
6. Enable Kafka Bridge (Optional):
   ```
   scripts/08d-event-streams-kafka-bridge-config.sh
   ```
   Confirm the instance has been deployed successfully running the following command:
   ```
   oc get kafkabridge jgr-es-demo-bridge -n tools -o jsonpath='{.status.conditions[0].type}';echo
   ```
   You should get a response like this:
   ```
   Ready
   ```
7. Enable Kafka Connector base:
   ```
   scripts/08e-event-streams-kafka-connector-datagen-config.sh
   ```
   Confirm the instances has been deployed successfully before moving to the next step running the following command:
   ```
   oc get kafkaconnector -n tools
   ```
   Note this will take few minutes, but at the end you should get a response like this:
   ```
   NAME                 CLUSTER               CONNECTOR CLASS                                                         MAX TASKS   READY
   kafka-datagen        jgr-connect-cluster   com.ibm.eventautomation.demos.loosehangerjeans.DatagenSourceConnector   1           True
   kafka-datagen-avro   jgr-connect-cluster   com.ibm.eventautomation.demos.loosehangerjeans.DatagenSourceConnector   1           True
   kafka-datagen-reg    jgr-connect-cluster   com.ibm.eventautomation.demos.loosehangerjeans.DatagenSourceConnector   1           True
   ```
</details>
&nbsp; 

<details>
<summary>
F) Deploy Event Endpoint Management - EEM (optional): 
</summary>

1. Install EEM Catalog Source:
   ```
   oc apply -f catalog-sources/${CP4I_VER}/13-eem-catalog-source.yaml
   ```
   Confirm the catalog source has been deployed successfully before moving to the next step running the following command: 
   ```
   oc get catalogsources ibm-eventendpointmanagement-catalog -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState}';echo
   ```
   You should get a response like this:
   ```
   READY
   ```
2. Install EEM Operator:
   ```
   oc apply -f subscriptions/${CP4I_VER}/09-eem-subscription.yaml
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment ibm-eem-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME --ignore-not-found -o jsonpath='{.status.phase}';fi;echo 
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
3. Deploy EEM Manager instance:
   ```
   scripts/99-eem-manager-inst-deploy-ea.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventendpointmanagement eem-demo-mgr -n tools -o jsonpath='{.status.phase}';echo
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Running
   ```
4. Deploy EEM Gateway instance:
   ```
   scripts/99-eem-gateway-inst-deploy-ea.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventgateway eem-demo-gw -n tools -o jsonpath='{.status.phase}';echo
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Running
   ```
5. Integrate EEM with ES instance (optional):
   1. Run script:
      ```
      scripts/19f-eem-es-config.sh
      ```
6. Configure EEM Manager security:
   1. Set the user passwords via environment variables:
      ```
      export EEM_ADMIN_PWD=<eem-admin-pwd>
      export EEM_USER_PWD=<es-user-pwd> 
      ```
   2. Run script:
      ```
      scripts/19a-eem-manager-config-sec.sh 
      ```
7. Post deployment EEM instance configuration:
   1. Get token for post deployment configuration:

      Follow instructions listed [here](https://ibm.github.io/event-automation/eem/security/api-tokens/#creating-a-token)

   2. Set environment variable for token:
      ```
      export EEM_TOKEN=<my-eem-token>
      ```
   3. Populate EEM Catalog:
      ```
      scripts/19e-eem-manager-config.sh
      ```
</details>
&nbsp; 

<details>
<summary>
G) Deploy Event Processing (optional): 
</summary>

1. Install Apache Flink Catalog Source:
   ```
   oc apply -f catalog-sources/${CP4I_VER}/14-ea-flink-catalog-source.yaml
   ```
   Confirm the catalog source has been deployed successfully before moving to the next step running the following command: 
   ```
   oc get catalogsources ibm-eventautomation-flink-catalog -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState}';echo
   ```
   You should get a response like this:
   ```
   READY
   ```
2. Install Apache Flink Operator:
   ```
   oc apply -f subscriptions/${CP4I_VER}/10-ea-flink-subscription.yaml
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment flink-kubernetes-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME --ignore-not-found -o jsonpath='{.status.phase}';fi;echo
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
3. Prepare TrustStore for Event Automation:
   ```
   scripts/20d-ea-truststore-config.sh
   ```
4. Deploy Apache Flink instance:
   ```
   oc apply -f instances/${CP4I_VER}/common/21-ea-flink-instance.yaml
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get flinkdeployment ea-flink-demo -n tools -o jsonpath='{.status.jobManagerDeploymentStatus}';echo
   ```
   You should get a response like this:
   ```
   READY
   ``` 
5. Install Event Processing Catalog Source:
   ```
   oc apply -f catalog-sources/${CP4I_VER}/15-event-processing-catalog-source.yaml
   ```
   Confirm the catalog source has been deployed successfully before moving to the next step running the following command: 
   ```
   oc get catalogsources ibm-eventprocessing-catalog -n openshift-marketplace -o jsonpath='{.status.connectionState.lastObservedState}';echo
   ```
   You should get a response like this:
   ```
   READY
   ```
6. Install Event Processing Operator:
   ```
   oc apply -f subscriptions/${CP4I_VER}/11-event-processing-subscription.yaml
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment ibm-ep-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME --ignore-not-found -o jsonpath='{.status.phase}';fi;echo
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
7. Deploy Event Processing instance:
   ```
   scripts/20b-ea-ep-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventprocessing ep-demo -n tools -o jsonpath='{.status.phase}';echo
   ```
   You should get a response like this:
   ```
   Running
   ``` 
8. Configure Event Processing security:
   1. Set the user password via environment variable:
      ```
      export EP_ADMIN_PWD=<ep-admin-pwd>
      ```
   2. Run script:
      ```
      scripts/20b-ea-ep-config-sec.sh
      ```
9. Install PGSQL Operator:
   ```
   oc apply -f resources/12a-pgsql-subscription.yaml
   ```
   Confirm the operator has been deployed successfully before moving to the next step running the following command:
   ```
   SUB_NAME=$(oc get deployment pgo -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME --ignore-not-found -o jsonpath='{.status.phase}';fi;echo
   ```
   You should get a response like this:
   ```
   Succeeded
   ```
10. Create configmap with db configuration:
   ```
   oc apply -f resources/12b-pgsql-config.yaml -n tools
   ```
11. Deploy a PGSQL DB instance:
      ```
      oc apply -f resources/12c-pgsql-db.yaml -n tools
      ```
      Confirm the instance has been deployed successfully before moving to the next step running the following command:
      ```
      oc get pods -l "postgres-operator.crunchydata.com/role=master" -n tools -o jsonpath='{.items[0].status.conditions[1].status}';echo
      ```
      After a few minutes you should get a response like this:
      ```
      True
      ``` 
12. Get information to access EA instances:
      ```
      scripts/99-ea-access-info.sh
      ```
</details>
&nbsp; 

Now you are ready to start the tutorials. Have fun!