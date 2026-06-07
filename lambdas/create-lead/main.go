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
    "github.com/aws/aws-lambda-go/events"
)


type Lead struct {
	Email     string  `json:"email" dynamodbav:"email"`
	First     string  `json:"first" dynamodbav:"first"`
	Last      string  `json:"last" dynamodbav:"last"`
	CareLevel string  `json:"careLevel" dynamodbav:"careLevel"`
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

func HandleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if event.Body == "" {
		log.Printf("Empty request body")
		return events.APIGatewayProxyResponse{StatusCode: 400}, fmt.Errorf("empty request body")
	}

	var lead Lead
	if err := json.Unmarshal([]byte(event.Body), &lead); err != nil {
		log.Printf("Failed to unmarshal event: %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 400}, err
	}

	jsonBytes, _ := json.Marshal(lead)
	fmt.Println("Processing lead:", string(jsonBytes))

	item, err := attributevalue.MarshalMap(lead)
	if err != nil {
		log.Printf("failed to marshal lead, %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	_, err = dbClient.PutItem(context.TODO(), &dynamodb.PutItemInput{
		TableName: aws.String("leads"),
		Item:      item,
	})
	if err != nil {
		log.Printf("failed to put item, %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	return events.APIGatewayProxyResponse{StatusCode: 201}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
