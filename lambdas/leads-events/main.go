package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/ses/types"
)

type EmailSender interface {
	SendTemplatedEmail(ctx context.Context, params *ses.SendTemplatedEmailInput, optFns ...func(*ses.Options)) (*ses.SendTemplatedEmailOutput, error)
}

var sesClient EmailSender

// init called by go runtime before main is called
func init() {
	// get empty context to work with
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		panic(err)
	}

	sesClient = ses.NewFromConfig(cfg)
}

func Handler(ctx context.Context, event events.DynamoDBEvent) error {
	for _, record := range event.Records {
		json, _ := json.Marshal(record)
		fmt.Println("Processing record:", string(json))

		switch record.EventName {
		case "INSERT":
			handleInsert(ctx, record)
		case "MODIFY":
			handleModify(ctx, record)
		default:
			continue
		}
	}

	return nil
}

func handleInsert(ctx context.Context, record events.DynamoDBEventRecord) {
	fmt.Println("processing insert")

	if record.Change.NewImage == nil {
		fmt.Println("No NewImage found in INSERT record")
		return
	}

	// get new email
	emailAttr, ok := record.Change.NewImage["email"]
	if !ok || emailAttr.String() == "" {
		fmt.Println("INSERT record missing email")
		return
	}

	email := emailAttr.String()
	fmt.Println("New lead inserted:", email)

	// get new name
	firstAttr, ok := record.Change.NewImage["first"]
	if !ok || firstAttr.String() == "" {
		fmt.Println("INSERT record missing first")
		return
	}

	first := firstAttr.String()
	fmt.Println("New lead inserted:", first)

	err := sendValidationEmail(ctx, email, first)
	if err != nil {
		fmt.Printf("Error sendValidationEmail: %v", err)	
	}
}

func handleModify(ctx context.Context, record events.DynamoDBEventRecord) {
	fmt.Println("processing modify")

	if record.Change.NewImage == nil || record.Change.OldImage == nil {
		fmt.Println("Missing OldImage or NewImage in MODIFY record")
		return
	}

	oldValidatedAttr, okOld := record.Change.OldImage["validated"]
	newValidatedAttr, okNew := record.Change.NewImage["validated"]

	if !okOld || !okNew {
		fmt.Println("Validated field missing in MODIFY record")
		return
	}

	oldValidated := oldValidatedAttr.Boolean()
	newValidated := newValidatedAttr.Boolean()

	// Only trigger when validated flips false -> true
	if !oldValidated && newValidated {
		emailAttr, ok := record.Change.NewImage["email"]
		if !ok || emailAttr.String() == "" {
			fmt.Println("Validated record missing email")
			return
		}
		email := emailAttr.String()
		fmt.Println("Lead validated; sending full welcome email:", email)

		// TODO: send welcome email here
	}
}

func sendValidationEmail(ctx context.Context, toEmail, name string) error {
	input := &ses.SendTemplatedEmailInput{
		Source: aws.String("your-verified-email@domain.com"),
		Destination: &types.Destination{
			ToAddresses: []string{toEmail},
		},
		Template: aws.String("leadforge-welcome"),
		TemplateData: aws.String(fmt.Sprintf(`{
            "name": "%s"
        }`, name)),
	}

	_, err := sesClient.SendTemplatedEmail(ctx, input)

	return err
}

func main() {
	lambda.Start(Handler)
}
