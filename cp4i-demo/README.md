# IBM Cloud Pak for Integration - Event Automation installation demonstration

You will need to have installed the following tools in your workstation:

* [oc cli](https://docs.openshift.com/container-platform/4.8/cli_reference/openshift_cli/getting-started-cli.html)
* zip
* keytool
* openssl
* [jq](https://stedolan.github.io/jq/)
* [yq](https://github.com/mikefarah/yq)

Note some of the tools will be available after you deploy an instance of the capability you are working on.

Lastly, this guide assumes you already have an OCP cluster with the right version and capacity up and running in [TechZone](https://techzone.ibm.com/home), and that you are already logged into your OCP cluster. For best results I recomments you use OCP v4.16.x with 5 worker nodes 32 vCPUs X 128 GB memory each. If you need further instructions to provision a cluster in TechZone follow this [link](TechZoneGuide.md).

Once you confirm you have the required tools in your workstation you are ready to use the following guide. 

Note the scripts used in this guide have been developed and tested on mac os. 

<details>
<summary>
A) Set environment variables:
</summary>

1. Set the CP4I version you want to install. The options available are either the latest LTS or CD releases, so use the following commands:
    ```
    export CP4I_VER=16.1.0
    or
    export CP4I_VER=16.1.1
    ```
2. Set the OCP type based on the storage classes in your cluster:
   1. Run command to identify the type you have to set up:
      ```
      oc get sc
      ```
      Your will get a response like this:
      ```
      NAME                                    PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
      localblock                              kubernetes.io/no-provisioner            Delete          WaitForFirstConsumer   false                  50d
      ocs-storagecluster-ceph-rbd (default)   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   50d
      ocs-storagecluster-ceph-rgw             openshift-storage.ceph.rook.io/bucket   Delete          Immediate              false                  50d
      ocs-storagecluster-cephfs               openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   50d
      openshift-storage.noobaa.io             openshift-storage.noobaa.io/obc         Delete          Immediate              false                  50d
      ```
      Or this one:
      ```
      NAME                                             PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
      ocs-external-storagecluster-ceph-rbd (default)   openshift-storage.rbd.csi.ceph.com      Delete          Immediate           true                   88d
      ocs-external-storagecluster-cephfs               openshift-storage.cephfs.csi.ceph.com   Delete          Immediate           true                   88d
      openshift-storage.noobaa.io                      openshift-storage.noobaa.io/obc         Delete          Immediate           false                  88d
      ```
   2. If you get the first response, then use the following command:
      ```
      export OCP_TYPE=ODF
      ```
      Otherwise use this command:
      ```
      export OCP_TYPE=TZEXT
      ```
</details>
&nbsp; 

<details>
<summary>
B) Deploy Event Streams: 
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
   scripts/08a-event-streams-inst-deploy.sh
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
6. Enable Kafka Connect for WatsonX (optional):
   ```
   scripts/08f-event-streams-kafka-connect-watsonx-config.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get kafkaconnects watsonx-demo-sources -n tools -o jsonpath='{.status.conditions[0].type}';echo
   ```
   Note this will take few minutes, but at the end you should get a response like this:
   ```
   Ready
   ```
7. Enable Kafka Bridge (Optional):
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
8. Enable Kafka Connector base:
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
9. Enable Kafka Connector Weather for WatsonX (optional):
      1. Set environment variable:
         ```
         export OPEN_WEATHER_API_KEY=<your-open-weather-api-key>
         ```
      2. Run script:
         ```
         scripts/08g-event-streams-kafka-connector-weather-config.sh
         ```
10. Enable Kafka Connector Weather for WatsonX (optional):
      1. Set environment variable:
         ```
         export ALPHA_VANTAGE_API_KEY=<your-alpha-vantage-api-key>
         ```
      2. Run script:
         ```
         scripts/08h-event-streams-kafka-connector-stock-prices-config.sh
         ```
11. Enable APIC Analytics offloading to Kafka Topic (optional):
      ```
      scripts/07k-apic-analytic-offload-config.sh
      ```
12. Enable APIC to work with EA for WatsonX (optional):
      1. Run script:
         ```
         scripts/07l-apic-gw-config-ea-watsonx.sh
         ```
      2. Set environment variable:
         ```
         export EA_WATSONX=YES
         ```
</details>
&nbsp; 

<details>
<summary>
C) Deploy Event Endpoint Management - EEM: 
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
3. Decide if you will integrate with KeyCloak or if you will use local security. If KeyCloak, set the following environment variable, otherwise go to the next step.
   ```
   export EA_OIDC=YES
   ```
4. Deploy EEM Manager instance:
   ```
   scripts/19a-eem-manager-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventendpointmanagement eem-demo-mgr -n tools --ignore-not-found -o jsonpath='{.status.phase}';echo
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Running
   ```
5. Deploy EEM Gateway instance:
   ```
   scripts/19b-eem-gateway-inst-deploy.sh
   ```
   Confirm the instance has been deployed successfully before moving to the next step running the following command:
   ```
   oc get eventgateway eem-demo-gw -n tools -o jsonpath='{.status.phase}';echo
   ```
   Note this will take few minutes, so be patient, but at the end you should get a response like this:
   ```
   Running
   ```
6. Integrate EEM with APIC instance (optional):
   1. Run script:
      ```
      scripts/19c-eem-tls-profiles-apic-config.sh
      ```
   2. Wait for the EEM Manager instance to restart before moving to the next step running the following command:
      ```
      oc get eventendpointmanagement eem-demo-mgr -n tools -o jsonpath='{.status.phase}';echo
      ```
      Note this will take few minutes, so be patient, but at the end you should get a response like this:
      ```
      Running
      ```
   3. Run script:
      ```
      scripts/19d-eem-gateway-apic-config.sh
      ```
      In some situations you may get the following error after running the script:
      ```
      Error: An error occurred communicating with the gateways subsystem at 'https://eem-demo-mgr-ibm-eem-apic-tools.apps.674a2f15e8a5a32b1ae1aed9.ocp.techzone.ibm.com' (error: 'Client network socket disconnected before secure TLS connection was established').
      ```
      If this is your case, check the EEM Manager instance state using the following command 
      ```
      oc get eventendpointmanagement eem-demo-mgr -n tools -o jsonpath='{.status.phase}';echo
      ```
      And once it is in *Running* state again re-run the script.
   4. Set environment variable:
      ```
      export EEM_APIC_INT=YES
      ```
7. Integrate EEM with ES instance (optional):
   1. Run script:
      ```
      scripts/19f-eem-es-config.sh
      ```
8. Configure EEM Manager security:
   Note that If you opted to use local security, the script will auto-generate the passwords for *eem-admin* and *eem-user*.
   ```
   scripts/19a-eem-manager-config-sec.sh 
   ```
9. Post deployment EEM instance configuration:
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
D) Deploy Event Processing (optional): 
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
   oc apply -f instances/${CP4I_VER}/21-ea-flink-instance.yaml -n tools
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
6. Decide if you will integrate with KeyCloak or if you will use local security. If KeyCloak, execute the following actions, otherwise go to the next step:
   1. Set the corresponding environment variable, 
      ```
      export EA_OIDC=YES
      ```
   2. Configure Keycloak Secret for EP running the following script:
      ```
      scripts/20e-ea-ep-oidc-config.sh
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
   1. Execute the corresponding script:
      ```
      scripts/20b-ea-ep-config-sec.sh
      ```
   2. If you enabled integration with KeyCloak then add the EP user role to *integration admin* to grant access, otherwise go to the next step.
9. Install PGSQL Operator (if you didn't do it as part of ACE, otherwise go to the next step):
   1. Create namespace:
      ```
      oc create namespace pgsql
      ```
   2. Enable Operator Group in namespace:
      ```
      oc apply -f resources/12d-pgsql-operatorgroup.yaml
      ```
   3. Install PGSQL Operator at namespace level:
      ```
      oc apply -f resources/12a-pgsql-subscription.yaml
      ```
      Confirm the operator has been deployed successfully before moving to the next step running the following command:
      ```
      SUB_NAME=$(oc get deployment pgo -n pgsql --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}');if [ ! -z "$SUB_NAME" ]; then oc get csv/$SUB_NAME -n pgsql --ignore-not-found -o jsonpath='{.status.phase}';fi;echo
      ```
      You should get a response like this:
      ```
      Succeeded
      ```
10. Deploy a PGSQL DB instance (if you didn't do it as part of ACE, otherwise go to the next step):
   1. Create configmap with db configuration:
      ```
      oc apply -f resources/12b-pgsql-config.yaml -n pgsql
      ```
   2. Create a PGSQL DB instance:
      ```
      oc apply -f resources/12c-pgsql-db.yaml -n pgsql
      ```
      Confirm the instance has been deployed successfully before moving to the next step running the following command:
      ```
      oc get pods -l "postgres-operator.crunchydata.com/role=master" -n pgsql -o jsonpath='{.items[0].status.conditions[1].status}' 2>/dev/null;echo
      ```
      After a few minutes you should get a response like this:
      ```
      True
      ``` 
11. Get information to access EA instances:
      ```
      scripts/20c-ea-access-info.sh
      ```
</details>
&nbsp; 
