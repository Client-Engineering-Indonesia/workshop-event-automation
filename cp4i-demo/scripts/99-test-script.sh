#!/bin/sh
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-h|i|n]"
   echo "options:"
   echo "h     Print this Help."
   echo "i     Provide Instance name."
   echo "n     Provide Namespace value."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Set default values for variables                         #
############################################################
NAMESPACE="tools"
INSTANCE="apim-demo"

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
         INSTANCE=$OPTARG;;
      n) # Update namespace value
         NAMESPACE=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

echo "Namespace:" $NAMESPACE
echo "Instance name:" $INSTANCE
OCSTATUS=$(oc whoami 2>&1)
echo "$OCSTATUS"
#case "$CP4I_VER" in
#    "2023"*) 
#        echo "Found it!"
#        ;;
#    *) 
#        echo "Something is wrong"
#        ;;
#esac
#if [[ "$CP4I_VER" == *"2023"* ]]
#then
#    echo "Found it!"
#else
#    echo "Something is wrong"
#fi
topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.ONLINE" "ORDERS.NEW" "STOCK.NOSTOCK" "SENSOR.READINGS" "STOCK.MOVEMENT" "PRODUCT.RETURNS" "PRODUCT.REVIEWS" "cp4i-es-demo-topic")
topicName=("JGR" "IAHA" "CAGH" "MJGH")
i=0
for topic in "${topics[@]}"
do
   echo $topic
   echo $i
   let "i+=1"
   echo ${topicName[0]}
done