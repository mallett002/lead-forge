use aws_lambda_events::apigw::{ApiGatewayProxyRequest, ApiGatewayProxyResponse};
use aws_sdk_dynamodb::Client as DynamoDbClient;
use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_dynamo::to_item;
use std::sync::OnceLock;

static DB_CLIENT: OnceLock<DynamoDbClient> = OnceLock::new();

#[derive(Deserialize, Serialize)]
struct Lead {
    #[serde(rename = "email")]
    email: String,
    #[serde(rename = "first")]
    first: String,
    #[serde(rename = "last")]
    last: String,
    #[serde(rename = "careLevel")]
    care_level: String,
    #[serde(rename = "createdAt")]
    created_at: String,
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    let config = aws_config::from_env()
        .region("us-east-1")
        .load()
        .await;

    let _ = DB_CLIENT.set(DynamoDbClient::new(&config));

    let handler = service_fn(handle_request);

    lambda_runtime::run(handler).await?;

    Ok(())
}

async fn handle_request(event: LambdaEvent<ApiGatewayProxyRequest>) -> Result<ApiGatewayProxyResponse, Error> {
    let client = DB_CLIENT.get().expect("DB_CLIENT not initialized");

    let body = event.payload.body.unwrap_or_default();

    if body.is_empty() {
        return Ok(ApiGatewayProxyResponse {
            status_code: 400,
            ..Default::default()
        });
    }

    let lead: Lead = match serde_json::from_str(&body) {
        Ok(l) => l,
        Err(e) => {
            eprintln!("Failed to unmarshal event: {e}");
            return Ok(ApiGatewayProxyResponse {
                status_code: 400,
                ..Default::default()
            });
        }
    };

    eprintln!("Processing lead: {}", serde_json::to_string(&lead).unwrap());

    let item = match to_item(&lead) {
        Ok(i) => i,
        Err(e) => {
            eprintln!("Failed to marshal lead: {e}");
            return Ok(ApiGatewayProxyResponse {
                status_code: 500,
                ..Default::default()
            });
        }
    };

    match client.put_item().table_name("leads").set_item(Some(item)).send().await {
        Ok(_) => Ok(ApiGatewayProxyResponse {
            status_code: 201,
            ..Default::default()
        }),
        Err(e) => {
            eprintln!("Failed to put item: {e}");
            Ok(ApiGatewayProxyResponse {
                status_code: 500,
                ..Default::default()
            })
        }
    }
}
