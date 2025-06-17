## Generating custom properties for custom filters

### Step 1 - Discover the topics to use

1. Go to the **Event Endpoint Management catalog**.
![alt text](images/lab-3/1.png)

2. The Promotions topic (wahyu-promotion-topic-config-1) contains events about **promotions** that are made.
![alt text](images/lab-2/event-information-lab-2.png)

### Step 2 - Provide a source of events

1. Click **Create** to create New Flow. and named as **(your-name) promotion flow**
![alt text](images/lab-3/create-new-flow-lab-3.png)

2. Click edit **event source**

3. Choose **add event source**
![alt text](images/lab-3/add-event-source-lab-3.png)

4. Fill credentials. You can get credentials of Topic Endpoint Managenet from subscribe on catalog menu on EEM.
![alt text](images/lab-2/create-subscribe-lab-2.png)
```
bootstrapserver=eem-demo-gw-ibm-egw-rt-tools.apps.itz-tx7iu2.infra01-lb.tok04.techzone.ibm.com:443

username=eem-2e6b6632-5ebe-4a7b-b1f1-673c121e78f7

password=4171bb61-a936-4e27-be8d-55bd83ef49ea
```

5. Choose topic (**wahyu-promotion-topic-config-1**) to add as source
![alt text](images/lab-3/choose-topic-as-source-lab-3.png)

6. Set massage format as JSON
![alt text](images/lab-3/message-format-lab-3.png)

7. Set Event details. set name as **promotions event source**
![alt text](images/lab-3/set-event-source-name.png)

### Step 3 : Checking category

1. Create a **Transform node**.
![alt text](images/lab-3/create-transform-node.png)
Create a transform node by dragging one onto the canvas. You can find this in the Processors section of the left panel.
Click and drag from the small gray dot on the event source to the matching dot on the transform node.

2. Hover over the transform node and click **Edit** icon Edit to configure the node.
Call the transform node **Mark isPublish**.
![alt text](images/lab-3/mark-as-publish.png)

3. Create a new property called **isPublish**.
![alt text](images/lab-3/create-prop-ispublish.png)
Suggested value for the property:

```IF(category = 'Internet', 0, 1)```

4. You can leave the other event properties as they are.

5. Click **Configure** to finalize the transform.
![alt text](images/lab-3/final-transform.png)

### Step 4 : Test the flow
The final step is to run your event processing flow and view the results.

1. Use the Run menu, and select Include historical to run your filter on the history of order events available on this Kafka topic.
![alt text](images/lab-3/run-test-lab-3.png)

2. Click the Filter node to see a live view of results from your filter. It is updated as new events are emitted onto the promotion topic.
![alt text](images/lab-3/final-result-lab-3.png)

3. When you have finished reviewing the results, you can stop this flow.