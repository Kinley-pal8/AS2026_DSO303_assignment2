# Viva preparation – likely questions and short answers

**Why serverless instead of EC2 + Auto Scaling?**
The load is spiky: almost nothing between exams, then 3,000 students arrive within 5 minutes. Lambda scales in seconds and costs nothing while idle. EC2 Auto Scaling needs minutes to add instances, so we'd have to keep capacity warm. For a known exam start time, provisioned concurrency removes cold starts.

**Why both DynamoDB and RDS?**
Autosave means many tiny writes to one key, about 100 per second at peak. DynamoDB on-demand handles that with no connection limits. Results, exams and submissions are relational and need joins and transactions, so they live in PostgreSQL. Splitting them means autosave can't overload the relational database.

**What stops 3,000 Lambdas from opening 3,000 database connections?**
RDS Proxy pools them. The SQS event source mappings also cap the marker at 20 concurrent workers and the uploads worker at 10.

**How is the exam time limit enforced if a student edits the JavaScript?**
On the server. The DynamoDB update has `ConditionExpression attempt_status = IN_PROGRESS AND deadline_epoch >= now − 60s`, and the deadline is set by the server at start. The browser timer is only for display.

**Can a student see the correct answers?**
No. `core.public_paper()` removes the `answer` field before the paper is returned, and only staff can call `GET /exams/{id}` with the full questions.

**Why not upload through the API?**
API Gateway caps payloads at 10 MB and Lambda at 6 MB. A presigned POST sends the 50 MB file straight to S3, and S3 itself enforces the 50 MB limit, the key and the content type.

**What happens if an AZ fails mid-exam?**
Lambda runs in the other AZ's subnet. RDS promotes its synchronous standby in 1–2 minutes with no data loss, and RDS Proxy reconnects. DynamoDB, S3, SQS and Cognito are already multi-AZ. The browser keeps answers in localStorage and retries every 30 s, so the student loses nothing.

**How do you meet RPO 5 min / RTO 1 h?**
RPO: answers are saved every 30 s to DynamoDB, which replicates across 3 AZs and has point-in-time recovery. RDS Multi-AZ replication is synchronous, and its PITR uses 5-minute log backups. RTO: an AZ loss heals automatically in minutes. A logical disaster is handled by a PITR restore, or the whole stack is rebuilt with `terraform apply`, both well under 1 hour.

**Where is the database password?**
In Secrets Manager, generated and rotated by RDS. Only the RDS Proxy role can read it. Lambdas use 15-minute IAM auth tokens.

**Why is the WAF rate limit so high?**
On campus, all 3,000 students may share one public NAT IP. A typical limit (around 2,000 requests per 5 minutes) would block the whole exam hall.

**Why one NAT gateway per AZ?**
If both private subnets route through the NAT in AZ A, losing AZ A also cuts outbound access for AZ B. One NAT per AZ removes that dependency.

**How does CI/CD work, and where are the AWS keys?**
There are no stored keys. GitHub Actions uses OIDC to assume an IAM role that only `main` or the `production` environment of this repo can use. The pipeline runs the tests, builds the zip and runs `terraform apply`, then invalidates CloudFront and smoke-tests the deploy.

**What would you change for real production?**
- Scope down the deploy role
- Use an application database user instead of the master user
- Take SES out of the sandbox and set up DKIM on the university domain
- Federate Cognito with the university's identity provider
- Turn on `protect_data`
- Add a CloudTrail organisation trail
- Load-test with 3,000 virtual users before exam week
