package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
)

func rebalanceHandler(c *kafka.Consumer, e kafka.Event) error {
	switch ev := e.(type) {
	case kafka.AssignedPartitions:
		fmt.Printf("%% Rebalance: Assigned partitions: %v\n", ev.Partitions)
		c.Assign(ev.Partitions)
	case kafka.RevokedPartitions:
		fmt.Printf("%% Rebalance: Revoked partitions: %v\n", ev.Partitions)
		c.Unassign()
	}
	return nil
}

// LoadProperties reads the .properties file into kafka.ConfigMap
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
			continue // skip comments and empty lines
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
	// Define CLI flags like the original Kafka CLI tools
	topic := flag.String("topic", "", "Kafka topic to subscribe to")
	configFile := flag.String("consumer.config", "", "Path to consumer config properties file")

	flag.Parse()

	if *topic == "" || *configFile == "" {
		fmt.Println("Usage: ./kafka-consumer --broker-list <brokers> --topic <topic> --consumer.config <file>")
		os.Exit(1)
	}

	// Load properties from file
	configMap, err := LoadProperties(*configFile)
	if err != nil {
		fmt.Printf("Failed to load config file: %v\n", err)
		os.Exit(1)
	}

	// Add necessary default configs
	if _, exists := (*configMap)["group.id"]; !exists {
		configMap.SetKey("group.id", "go-kafka-consumer")
	}
	configMap.SetKey("auto.offset.reset", "earliest")

	// Create Kafka consumer
	consumer, err := kafka.NewConsumer(configMap)
	if err != nil {
		panic(fmt.Sprintf("Failed to create consumer: %s", err))
	}
	defer consumer.Close()

	// Subscribe to topic
	err = consumer.SubscribeTopics([]string{*topic}, rebalanceHandler)
	if err != nil {
		panic(fmt.Sprintf("Failed to subscribe to topic: %s", err))
	}

	fmt.Printf("Listening to topic %s...\n", *topic)

	// Signal handling (Ctrl+C)
	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	run := true
	for run {
		select {
		case sig := <-sigchan:
			fmt.Printf("Received signal %v: exiting\n", sig)
			run = false
		default:
			msg, err := consumer.ReadMessage(100 * time.Millisecond)
			if err == nil {
				fmt.Printf("Received: [%s] Key=%s Value=%s\n", msg.TopicPartition, string(msg.Key), string(msg.Value))
				consumer.CommitMessage(msg)
			} else {
				fmt.Printf("Error reading message: %v\n", err)
			}
		}
	}
}
