package main

import (
	// "fmt"
	"context"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	// "github.com/stretchr/testify/assert"
	// "github.com/stretchr/testify/require"
)

// TODO: why called here?
// create mock sendEmail struct
type mockSES struct {
	called bool
}

func (s *mockSES) SendTemplatedEmail(ctx context.Context, params *ses.SendTemplatedEmailInput, optFns ...func(*ses.Options)) (*ses.SendTemplatedEmailOutput, error) {
	s.called = true

	return &ses.SendTemplatedEmailOutput{}, nil
}

func TestLeadsTableStreamsLambda(t *testing.T) {
	event := events.DynamoDBEvent{
		Records: []events.DynamoDBEventRecord{
			{
				EventName: "INSERT",
				Change: events.DynamoDBStreamRecord{
					NewImage: map[string]events.DynamoDBAttributeValue{
						"email": events.NewStringAttribute("test@example.com"),
						"name":  events.NewStringAttribute("Will"),
					},
				},
			},
		},
	}

	mock := &mockSES{}
	sesClient = mock

	err := Handler(context.Background(), event)

	if err != nil {
		t.Fatal(err)
	}

	if !mock.called {
		t.Fatal("Failed. Mock not called.")
	}
}
