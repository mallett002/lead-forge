package main

/*
    API Gateway handler for /validate endpoint
    - GET /validate?email={email}&token={token}
    - looks up user by email
    - ensures validation token matches, if not, throws error (unprocessible entity?)
    - if validated is still false:
        - Updates leads table with:
            - validated: true
            - validatedAt: timestamp
            - validationToken: null (sets to null)
*/

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

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
	email := event.QueryStringParameters["email"]
	token := event.QueryStringParameters["token"]

	if email == "" || token == "" {
		return events.APIGatewayProxyResponse{StatusCode: 400}, fmt.Errorf("missing email or token query parameters")
	}

	// Query DynamoDB by email (hash key)
	result, err := dbClient.Query(ctx, &dynamodb.QueryInput{
		TableName:              aws.String("leads"),
		KeyConditionExpression: aws.String("email = :email"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":email": &types.AttributeValueMemberS{Value: email},
		},
	})
	if err != nil {
		log.Printf("failed to query leads table, %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	if len(result.Items) == 0 {
		return events.APIGatewayProxyResponse{StatusCode: 404}, fmt.Errorf("no lead found for email")
	}

	item := result.Items[0]

	// Check if already validated
	if b, ok := item["validated"].(*types.AttributeValueMemberBOOL); !ok || b.Value {
		return events.APIGatewayProxyResponse{StatusCode: 422}, fmt.Errorf("already validated")
	}

	// Check validation token matches
	if s, ok := item["validationToken"].(*types.AttributeValueMemberS); !ok || s.Value != token {
		return events.APIGatewayProxyResponse{StatusCode: 422}, fmt.Errorf("invalid token")
	}

	// Get createdAt (range key) for UpdateItem
	createdAt, ok := item["createdAt"].(*types.AttributeValueMemberS)
	if !ok {
		log.Printf("failed to get createdAt from item")
		return events.APIGatewayProxyResponse{StatusCode: 500}, fmt.Errorf("failed to get createdAt")
	}

	// Update: set validated=true, validatedAt=timestamp, remove validationToken
	_, err = dbClient.UpdateItem(ctx, &dynamodb.UpdateItemInput{
		TableName: aws.String("leads"),
		Key: map[string]types.AttributeValue{
			"email":     &types.AttributeValueMemberS{Value: email},
			"createdAt": &types.AttributeValueMemberS{Value: createdAt.Value},
		},
		UpdateExpression: aws.String("SET validated = :val, validatedAt = :ts REMOVE validationToken"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":val": &types.AttributeValueMemberBOOL{Value: true},
			":ts":  &types.AttributeValueMemberS{Value: time.Now().UTC().Format(time.RFC3339)},
		},
	})
	if err != nil {
		log.Printf("failed to update lead, %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    map[string]string{"Content-Type": "text/html"},
		Body:       "<html><body><h2>Email verified successfully!</h2><p>You may close this tab.</p></body></html>",
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
