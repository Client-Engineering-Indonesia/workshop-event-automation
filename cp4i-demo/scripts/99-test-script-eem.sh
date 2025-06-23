#!/bin/sh
topics=("CANCELLATIONS" "CUSTOMERS.NEW" "DOOR.BADGEIN" "ORDERS.ONLINE" "ORDERS.NEW" "STOCK.NOSTOCK" "SENSOR.READINGS" "STOCK.MOVEMENT" "PRODUCT.RETURNS" "PRODUCT.REVIEWS")
echo "Compare EVENT SOURCES"
for topic in "${topics[@]}"
do
   read -p "Press <Enter> to compare option for topic "$topic
   diff /Users/joel.gomez@us.ibm.com/git/event-automation-demo/eem-seed/eem-03-${topic}.json /Users/joel.gomez@us.ibm.com/git/cp4i-demo/templates/template-eem-eventsource-${topic}.json
   echo
done
echo "Compare OPTIONS"
for topic in "${topics[@]}"
do
   read -p "Press <Enter> to compare option for topic "$topic
   diff /Users/joel.gomez@us.ibm.com/git/event-automation-demo/eem-seed/eem-03-${topic}-option.json /Users/joel.gomez@us.ibm.com/git/cp4i-demo/templates/template-eem-option-${topic}.json
   echo
done
