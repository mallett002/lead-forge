## Overall flow:
### submit 
- api gateway -> lambda:
    - if not already in leads table
        - saves to leads table (email as PK to prevent dupes)
            - first,
            - last,
            - email,
            - level,
            - validated: false,
            - createdAt
            - validationToken (guid?)

### leads table
- new record --> streams trigger -> lambda
    - send email for validation (with validation token)
    - email has link for validating

### email link click
- (send validationToken & email) -> api gateway -> lambda
    - looks up user by email (hash key)
    - updates record (leads table)
        - validated: true
        - validatedAt: timestamp
        - validationToken: null (one-time use)

    - leads table -> streams trigger (validated: true):
        - send welcome email

### event bridge cron
- get count of how many people added email this week
- get count of how many people validated email this week
- send me email


## Other important pieces:
- DLQ on Lambdas (reliability)
- Add basic logging/metrics



