package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-lambda-go/lambda"
    "github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)


type Lead struct {
	Email     string  `json:"email" dynamodbav:"email"`
	First     string  `json:"first" dynamodbav:"first"`
	Last      string  `json:"last" dynamodbav:"last"`
	CareLevel float64 `json:"careLevel" dynamodbav:"careLevel"`
	CreatedAt string  `json:"createdAt" dynamodbav:"createdAt"`
}

var (
	dbClient *dynamodb.Client
)

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion("us-east-1"))
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}

	dbClient = dynamodb.NewFromConfig(cfg)
}

func HandleRequest(ctx context.Context, event json.RawMessage) error {
	// Parse the input event
	var lead Lead
	if err := json.Unmarshal(event, &lead); err != nil {
		log.Printf("Failed to unmarshal event: %v", err)
		return err
	}

	json, _ := json.Marshal(lead)
	fmt.Println("Processing lead:", string(json))

	item, err := attributevalue.MarshalMap(lead)
	if err != nil {
		log.Fatalf("failed to marshal lead, %v", err)
	}

	_, err = dbClient.PutItem(context.TODO(), &dynamodb.PutItemInput{
		TableName: aws.String("leads"),
		Item:      item,
	})
	if err != nil {
		log.Fatalf("failed to put item, %v", err)
	}

    // TODO: getting this error:
    // 2026/06/07 14:09:12 failed to put item, operation error DynamoDB:
    // PutItem, https response error StatusCode: 400,
    // RequestID: 482PNK52U2D140E1ARN56E7KSBVV4KQNSO5AEMVJF66Q9ASUAAJG, 
    // api error ValidationException: One or more parameter values are not valid.
    // The AttributeValue for a key attribute cannot contain an empty string value.
    // Key: email

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
