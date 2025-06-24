#!/bin/sh
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Script to deploy Event Streams instance"
   echo
   echo "Syntax: scriptTemplate [-h|i|n|s]"
   echo "options:"
   echo "h     Print this Help."
   echo "i     Provide Instance name."
   echo "n     Provide Namespace value."
   echo "s     Provide Storage Class type."
   echo "v     Provide CP4I version."
   echo
}

ValidatePreReqs()
{
   if [ ! command -v oc &> /dev/null ]
   then 
      echo "oc could not be found."
      exit 1
   fi
   if [[ -z "$(oc get deployment eventstreams-cluster-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}')" ]]
   then 
      echo "Event Streams Operator is not installed."
      exit 1
   fi   
}

ValidateEnv()
{
   case "$scType" in
      "ODF")
         ocpBlockStorage='ocs-storagecluster-ceph-rbd'
         ;;
      "ROKS")
         ocpBlockStorage='ibmc-block-gold'
         ;;
      *)
         echo "$scType is not a valid Storage Class Type."
         echo "Valid options are ODF or ROKS."
         exit 1
         ;;
   esac

   if [[ "$cp4iVer" != "16.1.0" ]] && [[ "$cp4iVer" != "16.1.1" ]]
   then 
      echo "$cp4iVer is not a valid version."
      echo "This script is for CP4I v16.1.0 or v16.1.1"
      exit 1
   fi

   if [[ -z "$(oc get sc --no-headers | awk -v scname=$ocpBlockStorage '$1 == scname {print $1}')" ]]
   then
      echo "Storage Class $ocpBlockStorage is not available in cluster."
      echo "Check the Storage Class Type matches your OCP cluster."
      exit 1
   fi

   if [[ -z "$(oc projects -q | awk -v ns=$esNamespace '$1 == ns {print $1}')" ]]
   then
      echo "Namespace $esNamespace doesn't exist."
      exit 1
   fi 

   if [[ -z "$(oc get secret ibm-entitlement-key -n $esNamespace --no-headers --ignore-not-found)" ]]
   then
      echo "Entitlement Key not available in namespace $esNamespace."
      exit 1
   fi
}

DeployESInstance()
{
   echo "Preparing Event Streams manifest..."
   ( echo "cat <<EOF" ; cat instances/${cp4iVer}/05x-event-streams-mm2-instance.yaml ;) | \
      ES_NAME=${esInstName} \
      OCP_BLOCK_STORAGE=${ocpBlockStorage} \
   sh > 05-event-streams-instance.yaml
   echo "Deploying Event Streams instance..."
   oc apply -f 05-event-streams-instance.yaml -n ${esNamespace}
   echo "Cleaning up temp files..."
   rm -f 05-event-streams-instance.yaml
   echo "Done! Check progress using the following command:"
   echo "oc get eventstreams ${esInstName} -n ${esNamespace} -o jsonpath='{.status.phase}';echo"
   echo "Note this will take few minutes, so be patient," 
   echo "at some point you may see some errors,"
   echo "but at the end you should get a Ready status."
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Set default values for global variables                  #
############################################################
esInstName="es-demo"
esNamespace="tools"
scType="ODF"
cp4iVer="16.1.1"

ValidatePreReqs

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":i:n:s:v:h"
# Get the options
while getopts ${OPTSTRING} option; do
   case $option in
      h) # display Help
         Help
         exit;;
      i) # Update instance name
         esInstName=$OPTARG;;
      n) # Update namespace value
         esNamespace=$OPTARG;;
      s) # Update storage class value
         scType=$OPTARG;;
      v) # Update storage class value
         cp4iVer=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

ValidateEnv

DeployESInstance