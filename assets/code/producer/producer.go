package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"

	"io/ioutil"

	kafka "github.com/confluentinc/confluent-kafka-go/v2/kafka"
)

// LoadProperties loads key=value config into kafka.ConfigMap
func LoadProperties(filePath string) (*kafka.ConfigMap, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open config file: %w", err)
	}
	defer file.Close()

	configMap := &kafka.ConfigMap{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])
		configMap.SetKey(key, value)
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error reading config file: %w", err)
	}
	return configMap, nil
}

func main() {
	topic := flag.String("topic", "", "Kafka topic to produce to")
	configFile := flag.String("producer.config", "", "Kafka config file")
	jsonFile := flag.String("json.file", "", "Path to JSON file to send")
	flag.Parse()

	if *topic == "" || *configFile == "" || *jsonFile == "" {
		fmt.Println("Usage: ./kafka-producer --topic <topic> --producer.config <file> --json.file <file.json>")
		os.Exit(1)
	}

	// Load Kafka config
	configMap, err := LoadProperties(*configFile)
	if err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Load JSON file
	data, err := ioutil.ReadFile(*jsonFile)
	if err != nil {
		fmt.Printf("Failed to read JSON file: %v\n", err)
		os.Exit(1)
	}

	// Decode JSON array
	var records []map[string]interface{}
	err = json.Unmarshal(data, &records)
	if err != nil {
		fmt.Printf("Failed to parse JSON: %v\n", err)
		os.Exit(1)
	}

	// Create Kafka producer
	producer, err := kafka.NewProducer(configMap)
	if err != nil {
		fmt.Printf("Failed to create producer: %v\n", err)
		os.Exit(1)
	}
	defer producer.Close()

	// Delivery report
	go func() {
		for e := range producer.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					fmt.Printf("❌ Delivery failed: %v\n", ev.TopicPartition.Error)
				} else {
					fmt.Printf("✅ Delivered to %v\n", ev.TopicPartition)
				}
			}
		}
	}()

	// Send each JSON object as a message
	for _, record := range records {
		payload, err := json.Marshal(record)
		if err != nil {
			fmt.Printf("❌ Failed to encode record: %v\n", err)
			continue
		}

		err = producer.Produce(&kafka.Message{
			TopicPartition: kafka.TopicPartition{Topic: topic, Partition: kafka.PartitionAny},
			Value:          payload,
		}, nil)

		if err != nil {
			fmt.Printf("❌ Produce error: %v\n", err)
		}
	}

	// Wait until all messages are delivered
	for producer.Len() > 0 {
		producer.Flush(1000)
	}
}
