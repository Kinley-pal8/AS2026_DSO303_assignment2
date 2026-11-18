# Task 3 – Building it in the Cloud Architecture Lab

A checklist for rebuilding the design in the Cloud Architecture Lab and capturing evidence. It follows the same names as Terraform so the lab build, diagram and code match one-to-one in the viva.

## 1. Build order

Place components tier by tier, and connect each one before moving on.

1. **Region `ap-south-1`** → **VPC `10.20.0.0/16`**.
2. Two **Availability Zones** (A, B). In each AZ, add three subnets:
   - Public `10.20.0.0/24` / `10.20.1.0/24` → **NAT Gateway** in each; **Internet Gateway** on the VPC.
   - Private app `10.20.10.0/24` / `10.20.11.0/24` → **Lambda** `api`, `marker`, `uploads` (place them in both).
   - Private data `10.20.20.0/24` / `10.20.21.0/24` → **RDS PostgreSQL primary** in A, **standby** in B (Multi-AZ link), **RDS Proxy** spanning both.
3. Security groups: `sg-lambda` → `sg-proxy` (5432) → `sg-db` (5432).
4. Gateway **VPC endpoints** for S3 and DynamoDB on the app route tables.
5. Edge (outside the VPC): **Route 53** → **CloudFront** (+ **WAF**, **ACM**) → origins **S3 web bucket** and **API Gateway**.
6. **Cognito User Pool** (groups students/tutors/admins), linked to API Gateway as a JWT authorizer.
7. Regional data services: **DynamoDB `attempts`**, **S3 `uploads`** (add a note on its lifecycle: IA 30 d → Glacier IR 180 d → Deep Archive 365 d → delete 1,825 d).
8. Async: **SQS** `marking`, `uploads`, `notifications`, each with a **DLQ**. Then add **Lambda** `notifier` → **SES**, and **EventBridge** (1 min) → **Lambda** `sweeper`.
9. Cross-cutting: **KMS**, **Secrets Manager** (link to RDS/Proxy), **CloudWatch** + **SNS**, **AWS Backup** (link to RDS + DynamoDB), **IAM**.
10. CI/CD: **GitHub** → **GitHub Actions** → (OIDC) **IAM role** → **Terraform** → stack; **S3** state bucket.

Before simulating, check:
- [ ] Nothing in the data subnets is public, and RDS has *publicly accessible = no*
- [ ] Every compute and data component that lives in a subnet appears in **both** AZs
- [ ] Every queue has a DLQ
- [ ] Encryption at rest is turned on for RDS, DynamoDB and S3, and every edge connection is HTTPS

## 2. Simulation 1 – Student opens exam, answers autosave

Trace or animate this path (and set the load to the exam peak if the lab supports it: 3,000 users, 100 req/s):

`Student → Route 53 → CloudFront (WAF) → Cognito (sign-in)` →
`CloudFront /api → API Gateway (JWT) → Lambda api (AZ A) → RDS Proxy → RDS primary` (load exam) →
`Lambda api → DynamoDB` (create attempt) → **repeat every 30 s:** `→ API Gateway → Lambda api → DynamoDB` (autosave) →
`submit → SQS marking → Lambda marker → RDS` → `release → SQS notifications → Lambda notifier → SES → student`.

📸 Screenshot: `evidence/screenshots/lab-flow1-exam-autosave.png`

## 3. Simulation 2 – 40 MB assignment upload, tutor notified

`Student → CloudFront → API Gateway → Lambda api` (presigned POST) →
`Student → S3 uploads` (40 MB direct) → `S3 event → SQS uploads → Lambda uploads → RDS (record)` →
`SQS notifications → Lambda notifier → SES → Tutor`.

📸 Screenshot: `evidence/screenshots/lab-flow2-upload-notify.png`

## 4. Simulation 3 – Loss of one Availability Zone

1. Fail **AZ A** (or delete/stop every component in it: NAT A, Lambda A, RDS primary).
2. Show:
   - The RDS standby in AZ B is promoted to primary, and RDS Proxy now points at it.
   - The Lambda functions in the AZ B app subnet keep serving, through NAT B.
   - The regional services (CloudFront, API Gateway, DynamoDB, S3, SQS, Cognito) are unaffected.
3. Run Simulation 1 again. It should succeed through AZ B.

📸 Screenshots: `evidence/screenshots/lab-az-failure-before.png`, `evidence/screenshots/lab-az-failure-after.png`

## 5. Full build image

📸 `evidence/screenshots/lab-full-architecture.png`: the whole canvas, with both AZs, all tiers and the labels readable.
