### How to build producer

```go build -o bin/producer producer/producer.go```

### How to build producer on windows

```go build -o bin/producer.exe producer/producer.go```

### How to run producer
Format
```
./bin/producer \
    --topic <name target topic> \
    --producer.config <location config for .properties> \
    --json.file <location for file data to send to target topic>
```

Example
```
./bin/producer \
    --topic wahyu-promotion-topic \
    --producer.config config/producer.properties \
    --json.file data.json
```

### How to build consumer 

```go build -o bin/consumer consumer/consumer.go```

### How to build consumer on windows

```go build -o bin/consumer.exe consumer/consumer.go```

### How to run consumer
Format
```
./bin/consumer \
    --topic <name target topic> \
    --consumer.config <location config for .properties>
```

Example
```
./bin/consumer \
    --topic wahyu-promotion-topic \
    --consumer.config config/consumer.properties
```