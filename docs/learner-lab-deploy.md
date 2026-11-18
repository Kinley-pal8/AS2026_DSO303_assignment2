# Deploying in AWS Academy Learner Lab (free)

This deploys the same code as the production design, using the **Learner Lab profile** in [`infra/learner-lab.tfvars`](../infra/learner-lab.tfvars).

## What changes in Learner Lab and why

Learner Lab gives free credits but has three limits that matter here:
- It only allows the `us-east-1` and `us-west-2` regions.
- It does not let you create IAM roles. You must use the ready-made `LabRole`.
- Its access keys expire when the lab session ends, after about 4 hours.

| Production design (docs) | Learner Lab deployment | Why |
|---|---|---|
| One least-privilege IAM role per Lambda | All services use `LabRole` | IAM is read-only in the lab |
| Customer-managed KMS key | AWS-managed keys (`aws/rds`, SSE-S3, DynamoDB default) | Data is still encrypted at rest |
| RDS Proxy with IAM authentication | Lambdas connect straight to RDS over TLS, using the password RDS keeps in Secrets Manager | RDS Proxy needs its own IAM role |
| WAF, AWS Backup, VPC flow logs | Off | They need IAM roles or may be blocked |
| E-mail through SES | Each e-mail is written to CloudWatch Logs (`/aws/lambda/uniexam-prod-notifier`) | SES is not usable in the lab |
| GitHub OIDC deploy role | GitHub secrets hold the lab's session keys | OIDC needs an IAM role |
| NAT gateway in each AZ | One NAT (switch to two for the AZ-failure screenshot) | Saves lab credit |

Unchanged: the two-AZ VPC (public, app and data subnets), CloudFront, Cognito, API Gateway, Lambda, **RDS Multi-AZ**, DynamoDB, S3 with lifecycle rules, SQS with dead-letter queues, EventBridge, CloudWatch alarms and dashboard, and the push-to-deploy pipeline.

If you want to test whether the lab allows one of the switched-off services, set its line in `learner-lab.tfvars` to `true` and apply. If the apply fails with `AccessDenied`, set it back to `false`.

---

## Step 1: Start the lab and copy its keys
1. In AWS Academy, open **Learner Lab → Start Lab** and wait until the dot turns green.
2. Click **AWS Details → AWS CLI: Show**. You'll see a block like this:
   ```
   [default]
   aws_access_key_id=ASIA...
   aws_secret_access_key=...
   aws_session_token=...
   ```
3. On your laptop, save it as a profile called `lab`. Paste the block into `~/.aws/credentials` with the header renamed from `[default]` to `[lab]`:
   ```bash
   nano ~/.aws/credentials
   ```
4. Point your terminal at the lab (your terminal is currently set to the `floci` emulator):
   ```bash
   export AWS_PROFILE=lab AWS_REGION=us-east-1
   aws sts get-caller-identity
   ```
   This must show a real 12-digit account number and a role ending in `voclabs/...`.

> Repeat step 1 every time you start a new lab session, because the keys change each time.

## Step 2: Install Terraform (once)
```bash
mkdir -p ~/.local/bin && cd /tmp
curl -fLO https://releases.hashicorp.com/terraform/1.17.2/terraform_1.17.2_linux_amd64.zip
unzip -o terraform_1.17.2_linux_amd64.zip -d ~/.local/bin
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
terraform version
```

## Step 3: Create the Terraform state bucket (once)
```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws s3 mb s3://uniexam-tfstate-$ACCOUNT --region us-east-1
aws s3api put-bucket-versioning --bucket uniexam-tfstate-$ACCOUNT --versioning-configuration Status=Enabled
echo uniexam-tfstate-$ACCOUNT     # note this name
```

## Step 4: First deploy from your laptop
```bash
cd ~/Desktop/DSO303_as2
./scripts/build.sh
cd infra
terraform init -backend-config="bucket=uniexam-tfstate-$ACCOUNT" -backend-config="key=uniexam/prod.tfstate" \
               -backend-config="region=us-east-1" -backend-config="use_lockfile=true"
terraform apply -var-file=learner-lab.tfvars -var="initial_admin_email=YOUR_EMAIL"
```
Type `yes` when asked. The apply takes about 15–25 minutes, mostly for RDS Multi-AZ and CloudFront.

If the apply stops with an error, copy the error into the chat. It usually names the one service the lab blocked, and that service can be switched off in `learner-lab.tfvars`.

When it finishes:
```bash
terraform output app_url
```
Open the URL. Cognito e-mails you a temporary password from `no-reply@verificationemail.com`. Sign in with it and set a new password.

## Step 5: Connect GitHub so pushes redeploy automatically
1. Create an **empty** GitHub repository, then push the project:
   ```bash
   cd ~/Desktop/DSO303_as2
   git init -b main && git add . && git commit -m "Assignment 2"
   git remote add origin https://github.com/<you>/<repo>.git
   ```
2. In the GitHub repo, open **Settings → Secrets and variables → Actions**.
   - **Secrets**: add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`, copied from step 1.
   - **Variables**: add `AWS_REGION` = `us-east-1`, `LEARNER_LAB` = `true`, `TF_STATE_BUCKET` = the bucket from step 3, and `INITIAL_ADMIN_EMAIL` = your e-mail. Leave `AWS_DEPLOY_ROLE_ARN` unset.
3. In **Settings → Environments**, create `production`.
4. Run `git push -u origin main`. Then open the **Actions** tab and watch the run: test → apply → invalidate → smoke test. It reuses the same state, so it only changes what differs.

> Before a push in a **new** lab session, update the 3 secrets with the new keys. Everything else is automatic. Explain this in the viva as a Learner Lab limitation: on a normal account, the OIDC role in `infra/bootstrap` replaces stored keys.

## Step 6: Take the screenshots
Follow README section 5. For e-mails in the lab, open **CloudWatch → Log groups → `/aws/lambda/uniexam-prod-notifier`** and screenshot the `email_logged` entries (tutor notification, result released).

For the AZ-failure screenshot:
```bash
terraform apply -var-file=learner-lab.tfvars -var="nat_gateway_per_az=true"
../scripts/simulate-az-failover.sh
```

## Step 7: Tear down (do this before your credit runs low)
```bash
cd ~/Desktop/DSO303_as2/infra
terraform destroy -var-file=learner-lab.tfvars
```
The stack uses roughly $4–5 of lab credit per day, so destroy it once your screenshots are done. You can redeploy later with `terraform apply`.

Learner Lab stops some resources when a session ends, but **NAT gateways and RDS keep running and keep using credit**.
