# UniExam: online exams and assignment submission on AWS

DSO303 Assignment 2: Architecture Design and Deployment.

A university with 8,000 students and 400 staff moves exams and assignment submissions online. This repository contains the production architecture, the documentation for every service, and a working, fully-coded deployment. It is built with Terraform and deployed by GitHub Actions on every push to `main`.

**Report:** [docs/report.md](docs/report.md) is the full academic write-up covering the design, service choices, Cloud Architecture Lab results and evaluation.

| Requirement | How it is met |
|---|---|
| Role-based sign-in | Cognito user pool, groups `students` / `tutors` / `admins`, PKCE login, JWT authorizer on API Gateway |
| Timed MCQ and short-answer exams | Server-enforced deadline (conditional DynamoDB writes) and a sweeper that auto-submits when time runs out |
| Autosave every 30 s | Browser → `PUT /api/exams/{id}/answers` → DynamoDB on-demand, with a localStorage backup in the browser |
| Auto-marking of MCQs | Submit → SQS `marking` → Lambda `marker` → PostgreSQL `results` |
| Uploads (PDF/ZIP ≤ 50 MB) | Presigned S3 POST with `content-length-range`, straight from the browser; Lambda validates the magic bytes |
| E-mail on result release | SQS `notifications` → Lambda `notifier` → SES |
| 300–500 users normally; 3,000 starting in 5 minutes | CloudFront, serverless API, DynamoDB on-demand, RDS Proxy, queue-capped workers (see [architecture §3](architecture/README.md#3-exam-peak-and-loss-of-an-availability-zone-300-words)) |
| 99.9 % availability; survives the loss of one AZ | Two AZs for every tier, RDS Multi-AZ, a NAT gateway per AZ, regional managed services |
| RPO ≤ 5 min, RTO ≤ 1 h | 30 s autosave, RDS synchronous standby, DynamoDB and RDS point-in-time recovery, AWS Backup |
| Records kept 5 years; encryption in transit and at rest | S3 lifecycle expires at 1,825 days, monthly backups kept 5 years, KMS everywhere, TLS enforced |

## Repository layout

```
architecture/   README.md (diagram, tiers, peak + AZ-loss reasoning), walkthroughs.md, diagram.mmd, figure1-architecture.png
docs/           report.md (academic report), services.md (service table), cloud-architecture-lab.md (Task 3 build guide),
                learner-lab-deploy.md (free deployment), viva-notes.md
evidence/       Cloud Architecture Lab images, AWS screenshots, failover log
infra/          Terraform for the whole stack (network, edge, auth, api, compute, data, async, monitoring, backup)
infra/bootstrap Terraform state bucket + GitHub OIDC deploy role (run once)
backend/        Python 3.13 Lambda code (api, marker, uploads, notifier, sweeper)
frontend/       Static single-page app (vanilla JS, no build step)
scripts/        build.sh (package Lambdas), simulate-az-failover.sh
tests/          pytest unit tests (run in CI)
.github/        ci-cd workflow
```

## Deploy

> **Using AWS Academy Learner Lab (free)?** Follow **[docs/learner-lab-deploy.md](docs/learner-lab-deploy.md)** instead. It uses the same code with `infra/learner-lab.tfvars`, which runs everything as `LabRole` and switches off the services the lab can't create. The steps below are for a normal AWS account.

### Prerequisites
- An AWS account and the AWS CLI configured with an admin profile (`aws sts get-caller-identity` works)
- Terraform ≥ 1.10, Python 3.13 with pip, and git
- This folder pushed to **your own GitHub repository**

### 1. Bootstrap (once, from your laptop)
```bash
cd infra/bootstrap
terraform init
terraform apply -var="github_repo=<your-github-user>/<repo-name>"
# outputs: state_bucket, deploy_role_arn
# If the account already has the GitHub OIDC provider, add -var="create_oidc_provider=false"
```

### 2. Configure GitHub
In the repository, go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AWS_REGION` | `ap-south-1` (or your region) |
| `AWS_DEPLOY_ROLE_ARN` | `deploy_role_arn` output |
| `TF_STATE_BUCKET` | `state_bucket` output |
| `SES_SENDER_EMAIL` | an address you can open (it will be verified) |
| `ALARM_EMAIL` | where CloudWatch alarms go |
| `INITIAL_ADMIN_EMAIL` | your e-mail; becomes the first admin |

Then go to **Settings → Environments** and create `production`. You can add yourself as a required reviewer if you want a manual gate.

### 3. Push to `main`, and the pipeline deploys
```bash
git push origin main
```
`.github/workflows/deploy.yml` runs the unit tests and `terraform fmt`/`validate`, then assumes the AWS role via OIDC, builds the Lambda zip, runs `terraform apply`, invalidates CloudFront, and smoke-tests `/api/health`. The first apply takes about 20–25 minutes, mostly for RDS Multi-AZ and RDS Proxy. Later pushes take a few minutes.

<details><summary>Alternative: deploy from your laptop</summary>

```bash
./scripts/build.sh
cd infra
cp terraform.tfvars.example terraform.tfvars   # edit e-mails
terraform init -backend-config="bucket=<state_bucket>" -backend-config="key=uniexam/prod.tfstate" \
               -backend-config="region=ap-south-1" -backend-config="use_lockfile=true"
terraform apply
```
</details>

### 4. After the first deploy
1. **Click the SES verification link** sent to `SES_SENDER_EMAIL`.
2. A new account is in the **SES sandbox**, so it can only e-mail verified addresses. Verify the tutor and student test addresses too:
   `aws sesv2 create-email-identity --email-identity student@example.com` (then click the link in that inbox).
3. Confirm the **SNS alarm subscription** e-mail.
4. Open `terraform -chdir=infra output -raw app_url`. Sign in with the temporary password Cognito e-mailed to `INITIAL_ADMIN_EMAIL`, and set a new one.
5. As the admin, **invite a tutor and a student** from the Users panel. Use addresses you can open: plus-addressing such as `you+tutor@gmail.com` works.

### 5. Check it works and capture evidence

> **Deployed and verified on 19 November 2026** in AWS Academy Learner Lab (us-east-1) from AWS CloudShell. Every step below was run; the screenshots and the measured AZ-failover result (API outage of at most 17 seconds in three runs, no data lost) are listed in [`evidence/README.md`](evidence/README.md#aws-deployment-aws-academy-learner-lab-us-east-1).
Take each screenshot as you go and save it in `evidence/` under the filename shown.

1. **Tutor**: create an exam (sample questions are pre-filled) and an assignment.
2. **Student** (in another browser or a private window): start the exam, answer, and wait for **"Saved hh:mm:ss"**. 📸 `aws-app-student-exam.png`. Open the item in DynamoDB and show `answers` and `save_count`. 📸 `aws-dynamodb-attempt.png`. Submit.
3. **Tutor**: open Results. The MCQ score is already there, from SQS → `marker` → PostgreSQL. Enter a short-answer mark and click **Release**. 📸 `aws-results-email.png` (the student's e-mail).
4. **Student**: upload a ~40 MB PDF. 📸 `aws-s3-upload.png` (the object in S3 with SSE-KMS) and `aws-tutor-email.png` (the tutor's "New submission" e-mail).
5. **AZ failure**: run `./scripts/simulate-az-failover.sh`. The RDS primary moves to the other AZ while the deep health check recovers, and the timeline is saved to `evidence/az-failover-*.log`. 📸 `aws-rds-multi-az.png` (RDS console: Multi-AZ, new primary AZ).
6. **CI/CD**: change some text in `frontend/index.html` and push. 📸 `aws-github-actions-run.png` (the green run), then refresh the site to show the change.
7. 📸 `aws-cloudwatch-dashboard.png` (`terraform output dashboard_url`).

## Tear down

Tear everything down once your screenshots are taken, because this stack costs about **$4–5 per day** while running (two NAT gateways, Multi-AZ RDS, RDS Proxy, WAF).

```bash
cd infra
terraform destroy          # same -backend-config as init if you're on a new machine
# Lambda VPC network interfaces can take 10–20 min to release; re-run destroy if a subnet/SG is "in use".

cd bootstrap
aws s3 rm s3://$(terraform output -raw state_bucket) --recursive
aws s3api delete-objects --bucket $(terraform output -raw state_bucket) \
  --delete "$(aws s3api list-object-versions --bucket $(terraform output -raw state_bucket) \
  --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" || true
terraform destroy -var="github_repo=<your-github-user>/<repo-name>"
```
With `protect_data = false` (the coursework default), destroy also deletes the RDS instance without a final snapshot, the uploads bucket, and the backup vault's recovery points. For real production, set `protect_data = true`.

**Saving money while testing:** set `nat_gateway_per_az = false` to use a single NAT gateway. Turn it back on for the AZ-failure demo.

## Design notes and known limits
- The app connects as the RDS master user through the proxy, using IAM auth. In production, add a restricted application role.
- The GitHub deploy role has `AdministratorAccess` to keep the coursework simple. Scope it down and add a permissions boundary in production.
- SES needs a production-access request and a verified university domain (DKIM) before it can e-mail real students.
- Cognito can federate to the university's identity provider (SAML/OIDC) without code changes, because the API only trusts the group claims.
