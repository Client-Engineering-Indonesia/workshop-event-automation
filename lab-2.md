## Event Endpoint Management
Add a topic to Event Endpoint Management to make it available to others as an event source. In this guide, you are adding a topic to consume events from.

### Exposing topic event stream

1. In the navigation pane, click **Manage topics**.

2. Click **Add topic**.

![alt text](images/lab-2/1.png)
3. In the Interaction pane, select how your application will interact with the event source. Click Consume events and click Next.
![alt text](images/lab-2/2.png)

5. Select your cluster which you create topic previously (**maybank-cluster-es**).
![alt text](images/lab-2/choose-cluster-lab-2.png)

4. Select your topic from the list of topics available on this cluster.
![alt text](images/lab-2/choose-topic-lab-2.png)

10. **Optional**: If a name is not added by default, enter a unique event source name for the topic selected.

Note: The event source name is the unique ID that identifies your topics.

11. Click **Add Topic**. And you can see topic active on list page **Manage Topics**
![alt text](images/lab-2/active-topics-lab-2.png)

### Add Additional Information For Endpoint Topic
1. Click on the topic you previously created. You will be redirected to the detailed configuration page.
![alt text](images/lab-2/dashboard-detail-config-topic-lab-2.png)

2. Click **Edit Information** 
![alt text](images/lab-2/edit-information-lab-2.png)

3. Fill **Overview Information**
![alt text](images/lab-2/overview-topic-lab-2.png)

4. Go to **Event Information**
![alt text](images/lab-2/event-information-lab-2.png)
fill the detail:
   - Mesage format: JSON
   - Upload schema: [click here](assets/json/promotions.json)
   - Sample message: [click here](assets/json/sample.json)

5. Click **Save**

### Add Configuration From Topics Management

1. Click on the topic you previously created. You will be redirected to the detailed configuration page.
![alt text](images/lab-2/dashboard-detail-config-topic-lab-2.png)

2. Click Options on detail configuration.
![alt text](images/lab-2/click-options-lab-2.png)

3. Click On **Create Option**
![alt text](images/lab-2/click-create-option-lab-2.png)

4. Fill blank text box

    - Option Name: Configuration <**your-topic-name**>
    - Alias: <**your-topic-name-approval**>

![alt text](images/lab-2/filling-option-value-lab-2.png)

5. Add new control 
![alt text](images/lab-2/add-new-control-lab-2.png)

6. Choose **Approval** and **Schema Filtering** to add flow approval for this topic.
![alt text](images/lab-2/choose-approval-lab-2.png)

7. Click **Save**

8. You will redirect to main detail config page. in this page, click **Publish**
![alt text](images/lab-2/publish-endpoint-lab-2.png)

### Checking and Generate Access to Publihed Topic Endpoint

1. Click on **catalog** menu on navbar.
![alt text](images/lab-2/catalog-menu-lab-2.png)

2. Choose your topic
![alt text](images/lab-2/choose-your-topic-lab-2.png)

3. Page fill show how to connect and its rules.
![alt text](images/lab-2/detail-management-topic-lab-2.png)

4. Click Request Access and fill the form
![alt text](images/lab-2/request-access-lab-2.png)

5. Go to page access request and accept the request
![alt text](images/lab-2/access-page-lab-2.png)

6. Approve request
![alt text](images/lab-2/approve-request-access-lab-2.png)

7. Subscribe the Topic
![alt text](images/lab-2/subscribe-approved-topic.png)

8. Credential Generated
![alt text](images/lab-2/credential-generated-lab-2.png)