package main

import (
    "context"
    "encoding/json"
    "fmt"

    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, event events.DynamoDBEvent) error {
    for _, record := range event.Records {
        recJSON, _ := json.Marshal(record)
        fmt.Println("Processing record:", string(recJSON))

        switch record.EventName {
        case "INSERT":
            handleInsert(record)
        case "MODIFY":
            handleModify(record)
        default:
            continue
        }
    }

    return nil
}

func handleInsert(record events.DynamoDBEventRecord) {
    if record.Change.NewImage == nil {
        fmt.Println("No NewImage found in INSERT record")
        return
    }

    emailAttr, ok := record.Change.NewImage["email"]
    if !ok || emailAttr.String() == "" {
        fmt.Println("INSERT record missing email")
        return
    }

    email := emailAttr.String()
    fmt.Println("New lead inserted:", email)
    // TODO: send validation email here
}

func handleModify(record events.DynamoDBEventRecord) {
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

func main() {
    lambda.Start(handler)
}
