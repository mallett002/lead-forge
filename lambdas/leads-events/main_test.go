package main

import (
	"context"
	"testing"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/stretchr/testify/mock"
)

type MockEmailSender struct {
	mock.Mock
}

func (m *MockEmailSender) SendTemplatedEmail(ctx context.Context, params *ses.SendTemplatedEmailInput, optFns ...func(*ses.Options)) (*ses.SendTemplatedEmailOutput, error) {
	args := m.Called(ctx, params)
	return args.Get(0).(*ses.SendTemplatedEmailOutput), args.Error(1)
}

func setupInsert() *MockEmailSender {
	mockSender := &MockEmailSender{}

	mockSender.On("SendTemplatedEmail", mock.Anything, mock.Anything).Return(&ses.SendTemplatedEmailOutput{}, nil).Once()

	sesClient = mockSender

	return mockSender
}

func TestLeadsTableStreamsLambdaInsert(t *testing.T) {
	// given
	mockSender := setupInsert()

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

	// when
	Handler(context.Background(), event)

	// then
	mockSender.AssertCalled(t, "SendTemplatedEmail", mock.Anything, mock.Anything)
	mockSender.AssertNumberOfCalls(t, "SendTemplatedEmail", 1)
}
