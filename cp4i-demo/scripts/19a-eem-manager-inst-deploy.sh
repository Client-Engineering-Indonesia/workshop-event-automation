#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
###################
# INPUT VARIABLES #
###################
EEM_INST_NAME='eem-demo-mgr'
EEM_NAMESPACE='tools'
echo "Setting Storage Class..."
case "$OCP_TYPE" in
    "ODF")
        OCP_BLOCK_STORAGE='ocs-storagecluster-ceph-rbd'
        ;;
    "ROKS")
        OCP_BLOCK_STORAGE='ibmc-block-gold'
        ;;
    "TZEXT")
        OCP_BLOCK_STORAGE='ocs-external-storagecluster-ceph-rbd'
        ;;
   *)
      echo "Incorrect Storage Class Type. Check Environment Variable OCP_TYPE."
      exit 1
      ;;
esac
cp instances/${CP4I_VER}/19-eem-manager-local-instance.yaml .
if [ -z "$EA_OIDC" ]
then
    echo "Deploying EEM Manager instance with local security..."
    EEM_AUTH_TYPE='LOCAL'
else
    echo "Deploying EEM Manager instance with OIDC security..."
    EEM_AUTH_TYPE='INTEGRATION_KEYCLOAK'
    yq -i '.spec.manager.template.pod.spec.containers[0].env[1].name = "EI_AUTH_OAUTH2_ADDITIONAL_SCOPES" | 
        .spec.manager.template.pod.spec.containers[0].env[1].value = "email,profile,offline_access" | 
        .spec.manager.template.pod.spec.containers[0].env[1].value style="single"' 19-eem-manager-local-instance.yaml
fi
( echo "cat <<EOF" ; cat 19-eem-manager-local-instance.yaml ;) | \
EEM_AUTH_TYPE=${EEM_AUTH_TYPE} \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
sh > eem-manager-local-instance.yaml
oc apply -f eem-manager-local-instance.yaml -n ${EEM_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 19-eem-manager-local-instance.yaml
rm -f eem-manager-local-instance.yaml
echo "Done! Check progress..."