# Evidence

Put screenshots and logs here. Use the filenames below; the README and docs link to them.

## Cloud Architecture Lab (Task 3)

Screenshots are in [`screenshots/`](screenshots/). The matching lab exports are in [`lab-json/`](lab-json/); import any of them into the Cloud Architecture Lab to reopen that exact canvas.

| File | Shows |
|---|---|
| [`lab-full-architecture.png`](screenshots/lab-full-architecture.png) | Complete build: VPC, 2 AZs, public / app / data subnets, edge, async, monitoring, CI/CD |
| [`lab-flow1-exam-autosave.png`](screenshots/lab-flow1-exam-autosave.png) | Walkthrough 1 simulated (exam open + autosave) |
| [`lab-flow2-upload-notify.png`](screenshots/lab-flow2-upload-notify.png) | Walkthrough 2 simulated (40 MB upload → tutor e-mail) |
| [`lab-az-failure-before.png`](screenshots/lab-az-failure-before.png) / [`lab-az-failure-after.png`](screenshots/lab-az-failure-after.png) | AZ A failed; traffic served from AZ B, RDS standby promoted |

## AWS deployment (AWS Academy Learner Lab, us-east-1)

The stack was deployed with `terraform apply -var-file=infra/learner-lab.tfvars` from AWS CloudShell. The lab blocks some services, so the Learner Lab profile differs from the production design; see [`../docs/learner-lab-deploy.md`](../docs/learner-lab-deploy.md). The main difference is that API Gateway serves the app, because the lab denies CloudFront.

| File | Shows | Rubric item |
|---|---|---|
| [`aws-health-check.png`](screenshots/aws-health-check.png) | `GET /api/health?deep=1` returns `db: ok`: API Gateway → Lambda in the private subnets → PostgreSQL | API working |
| [`aws-network-2az.png`](screenshots/aws-network-2az.png) | 6 subnets: public, app and data tiers in us-east-1a and us-east-1b | Two AZs |
| [`aws-rds-multi-az.png`](screenshots/aws-rds-multi-az.png) | RDS PostgreSQL: Multi-AZ true, primary and standby in different AZs, not public, encrypted | Two-AZ database |
| [`aws-lambdas.png`](screenshots/aws-lambdas.png) | Six arm64 Python 3.13 functions; api, marker and uploads in both private app subnets | API / compute |
| [`aws-api-routes.png`](screenshots/aws-api-routes.png) | API Gateway routes: JWT authorizer on `/api/*` | Security |
| [`aws-cognito-users.png`](screenshots/aws-cognito-users.png) | Admin, tutor and student users in their Cognito groups | Role-based sign-in |
| [`aws-app-admin.png`](screenshots/aws-app-admin.png) | The app signed in as administrator | Frontend working |
| [`app-student-exam.png`](screenshots/app-student-exam.png) | Student taking the exam, timer and "Saved hh:mm:ss" visible | Frontend + autosave |
| [`aws-dynamodb-attempt.png`](screenshots/aws-dynamodb-attempt.png) | The attempt in DynamoDB with autosaved `answers` and `save_count` | Autosave |
| [`aws-s3-upload.png`](screenshots/aws-s3-upload.png) | Uploaded PDF in `submissions/…`, server-side encrypted; lifecycle rules (IA 30 d → Glacier IR → Deep Archive → delete at 5 years) | S3 uploads |
| [`aws-tutor-email.png`](screenshots/aws-tutor-email.png) | Async step: S3 event → SQS → `uploads` Lambda → SQS → `notifier`: "New submission" e-mail to the tutor plus the student's receipt (written to CloudWatch Logs, since SES is unavailable in the lab) | Async step |
| [`aws-results-email.png`](screenshots/aws-results-email.png) | "Result released" e-mail after the tutor released marks | Async step |
| [`aws-sqs-queues.png`](screenshots/aws-sqs-queues.png) | Marking, uploads and notifications queues, each with a dead-letter queue (`maxReceiveCount` 5) | Async step |
| [`aws-alarms.png`](screenshots/aws-alarms.png) | CloudWatch alarms | Monitoring |
| [`aws-az-failover.png`](screenshots/aws-az-failover.png), [`az-failover.log`](az-failover.log) | Forced RDS Multi-AZ failover while polling the API every 2–3 s: **API outage of at most 17 seconds** in each of three runs, primary moved between us-east-1a and us-east-1b, no data lost | Loss of one AZ |

**AZ failure result:** three forced failovers were run (full timeline in [`az-failover.log`](az-failover.log)). The API was unavailable for at most **16 s, 14 s and 17 s**: one request timed out and one or two returned 503 while the standby was promoted, then everything returned to normal on its own. The primary moved between us-east-1a and us-east-1b each time. Autosave is not affected by a database failover, because it writes to DynamoDB.

## CI test job (local run)

[`ci-local-test-run.log`](ci-local-test-run.log): the same steps as the pipeline's `test` job, run locally while GitHub Actions was blocked by an account billing lock. 17 unit tests passed, `terraform fmt` and `validate` passed, and `terraform test` passed for both the production and Learner Lab profiles.
