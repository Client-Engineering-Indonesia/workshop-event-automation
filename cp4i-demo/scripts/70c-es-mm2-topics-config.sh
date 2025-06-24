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
   if [[ -z $(oc get deployment eventstreams-cluster-operator -n openshift-operators --ignore-not-found -o jsonpath='{.metadata.labels.olm\.owner}') ]]
   then 
      echo "Event Streams Operator is not installed."
      exit 1
   fi   
}

ValidateEnv()
{
   if [[ -z "$(oc projects -q | awk -v ns=$esNamespace '$1 == ns {print $1}')" ]]
   then
      echo "Namespace $esNamespace doesn't exist."
      exit 1
   fi

   if [[ -z "$(oc get eventstreams $esInstName -n $esNamespace --no-headers --ignore-not-found)" ]]
   then
      echo "$esInstName instance is not available in namespace $esNamespace."
      echo "Check the values and try again."
      exit 1
   fi 

   if [[ "$(oc get eventstreams $esInstName -n $esNamespace -o jsonpath='{.status.phase}')" != "Ready" ]]
   then
      echo "$esInstName instance is not ready yet. Wait until it is ready to run this script."
      exit 1
   fi
}

DefineTopics()
{
   echo "Preparing Topics..."
   ( echo "cat <<EOF" ; cat templates/template-es-mm2-kafka-topics.yaml ;) | \
      CLUSTER_NAME=${esInstName} \
   sh > es-mm2-kafka-topics.yaml
   echo "Defining Topics..."
   oc apply -f es-mm2-kafka-topics.yaml
   echo "Cleaning up temp files..."
   rm -f es-mm2-kafka-topics.yaml
   echo "Done! Topics have been defined..."
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

ValidatePreReqs

############################################################
# Process the input options. Add options as needed.        #
############################################################
OPTSTRING=":i:n:h"
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
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

ValidateEnv

DefineTopics