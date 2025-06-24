#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
echo "Configuring Kafka Connector Weather for WatsonX..."
##################################
# KAFKA CONNECTOR WEATHER CONFIG #
##################################
echo "Updating template with config info..."
( echo "cat <<EOF" ; cat templates/template-es-kafka-connector-weather.yaml ;) | \
    OPEN_WEATHER_API_KEY=${OPEN_WEATHER_API_KEY} \
    sh > es-kafka-connector-weather.yaml
echo "Creating Kafka Connector Weather instance..."
oc apply -f es-kafka-connector-weather.yaml
echo "Cleaning up temp files..."
rm -f es-kafka-connector-weather.yaml
echo "Kafka Connector Weather has been configured."