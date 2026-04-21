package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	// "github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)


type Lead struct {
	Email		string  `json:"email"`
	First		string  `json:"first"`
	Last		string  `json:"last"`
	CareLevel	float64 `json:"careLevel"`
	Timestamp   string `json:"timestamp"`
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

	// For now just list the tables
	// resp, err := dbClient.ListTables(context.TODO(), &dynamodb.ListTablesInput{
	//        Limit: aws.Int32(5),
	//    })
	//    if err != nil {
	//        log.Fatalf("failed to list tables, %v", err)
	//    }
	//
	//    fmt.Println("Tables:")
	//    for _, tableName := range resp.TableNames {
	//        fmt.Println(tableName)
	//    }

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
