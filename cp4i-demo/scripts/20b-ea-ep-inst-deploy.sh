#!/bin/sh
# This script requires the oc command being installed in your environment
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$CP4I_VER" ]; then echo "CP4I_VER not set, it must be provided on the command line."; exit 1; fi;
if [ -z "$OCP_TYPE" ]; then echo "OCP_TYPE not set, it must be provided on the command line."; exit 1; fi;
echo "CP4I_VER is set to" $CP4I_VER
if [ "$CP4I_VER" != "16.1.0" ] && [ "$CP4I_VER" != "16.1.1" ]; then echo "This script is for CP4I v16.1.*"; exit 1; fi;
echo "OCP_TYPE is set to" $OCP_TYPE
read -p "Press <Enter> to execute script..."
EP_NAMESPACE='tools'
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
cp instances/${CP4I_VER}/22-event-processing-instance.yaml .
if [ -z "$EA_OIDC" ]
then
    echo "Deploying Event Processing instance with local security..."
    EP_AUTH_TYPE='LOCAL'
else
    echo "Deploying Event Processing instance with OIDC security..."
    EP_AUTH_TYPE='OIDC'
    yq -i '.spec.authoring.authConfig.oidcConfig.authorizationClaimPointer = "/effectiveRoles" |
        .spec.authoring.authConfig.oidcConfig.clientIDKey = "CLIENT_ID" |
        .spec.authoring.authConfig.oidcConfig.clientSecretKey = "CLIENT_SECRET" |
        .spec.authoring.authConfig.oidcConfig.discovery = true |
        .spec.authoring.authConfig.oidcConfig.secretName = "keycloak-client-secret-ep-demo-ibm-ep-keycloak" |
        .spec.authoring.authConfig.oidcConfig.site = "https://cpfs-opcon-cs-keycloak-service.ibm-common-services.svc:8443/realms/cloudpak/" | 
        .spec.authoring.authConfig.oidcConfig.site style="single" |
        .spec.authoring.tls.trustedCertificates[0].certificate = "ca.crt" |
        .spec.authoring.tls.trustedCertificates[0].secretName = "keycloak-bindinfo-cs-keycloak-tls-secret" | 
        .spec.authoring.template.pod.spec.containers[0].env[1].name = "EI_AUTH_VALIDATE_DISCOVERY_ISSUER" | 
        .spec.authoring.template.pod.spec.containers[0].env[1].value = "false" | 
        .spec.authoring.template.pod.spec.containers[0].env[1].value style="single"' 22-event-processing-instance.yaml              
fi
( echo "cat <<EOF" ; cat 22-event-processing-instance.yaml ;) | \
EP_AUTH_TYPE=${EP_AUTH_TYPE} \
OCP_BLOCK_STORAGE=${OCP_BLOCK_STORAGE} \
sh > event-processing-instance.yaml
oc apply -f event-processing-instance.yaml -n ${EP_NAMESPACE}
echo "Cleaning up temp files..."
rm -f 22-event-processing-instance.yaml
rm -f event-processing-instance.yaml
echo "Done! Check progress..."