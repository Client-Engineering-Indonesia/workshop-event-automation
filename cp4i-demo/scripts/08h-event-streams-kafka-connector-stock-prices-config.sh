#!/bin/sh
if [ ! command -v oc &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
echo "Configuring Kafka Connector Stock Prices for WatsonX..."
#######################################
# KAFKA CONNECTOR STOCK PRICES CONFIG #
#######################################
echo "Updating template with config info..."
( echo "cat <<EOF" ; cat templates/template-es-kafka-connector-stock-prices.yaml ;) | \
    ALPHA_VANTAGE_API_KEY=${ALPHA_VANTAGE_API_KEY} \
    Value='$Value' \
    sh > es-kafka-connector-stock-prices.yaml
echo "Creating Kafka Connector Stock Prices instance..."
oc apply -f es-kafka-connector-stock-prices.yaml
echo "Cleaning up temp files..."
rm -f es-kafka-connector-stock-prices.yaml
echo "Kafka Connector Stock Prices has been configured."