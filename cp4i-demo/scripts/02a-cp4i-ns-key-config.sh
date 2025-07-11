#!/bin/sh
# This script requires the oc command being installed in your environment
# And before running the script you need to set an environment variable call "pwd" with your key, i.e. using this command: "export ENT_KEY=my-key"
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
if [ -z "$ENT_KEY" ]; then echo "ENT_KEY not set, it must be provided on the command line."; exit 1; fi;
echo "ENT_KEY is set to" $ENT_KEY
read -p "Press <Enter> to execute script..."
USER_NAME="cp"
# CP4I_NAMESPACES=(cp4i cp4i-ace cp4i-apic cp4i-aspera cp4i-assetrepo cp4i-dp cp4i-eventstreams cp4i-mq cp4i-tracing)
# CP4I_NAMESPACES=(student1 student2 student3 student4 student5 student6 student7 student8 student9 student10 student11 student12 student13 student14 student15 student16 student17 student18 student19 student20) 
CP4I_NAMESPACES=(tools cp4i cp4i-mq cp4i-dp cp4i-es mq-argocd stepzen london rome)
for NS in "${CP4I_NAMESPACES[@]}"
do
    echo "Creating a new namespace called" $NS
    if [[ -z "$(oc projects -q | awk -v ns=$NS '$1 == ns {print $1}')" ]]; then
        oc new-project $NS
    else
        echo "Namespace" $NS "already exists."
    fi 
    echo "Creating ibm-entitlement-key in namespace" $NS
    if [[ -z "$(oc get secret ibm-entitlement-key -n $NS --no-headers --ignore-not-found=true)" ]]; then
        oc create secret docker-registry ibm-entitlement-key \
            --docker-username=$USER_NAME \
            --docker-password=$ENT_KEY \
            --docker-server=cp.icr.io \
            --namespace=$NS
    else
        echo "ibm-entitlement-key already exists in namespace" $NS
    fi
done