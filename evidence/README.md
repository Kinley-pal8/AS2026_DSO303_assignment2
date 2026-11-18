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

## AWS deployment

| File | Shows |
|---|---|
| `aws-github-actions-run.png` | Green pipeline run triggered by a push to `main` (test → apply → invalidate → smoke test) |
| `aws-app-student-exam.png` | Student taking an exam, "Saved hh:mm:ss" visible |
| `aws-dynamodb-attempt.png` | DynamoDB item showing autosaved answers and `save_count` |
| `aws-rds-multi-az.png` | RDS console: Multi-AZ = Yes, primary and secondary AZ |
| `aws-s3-upload.png` | 40 MB object in `submissions/…` with SSE-KMS |
| `aws-tutor-email.png` | Tutor's "New submission" e-mail |
| `aws-results-email.png` | Student's "Result released" e-mail |
| `aws-cloudwatch-dashboard.png` | Dashboard during the demo |
| `az-failover-*.log` | Output of `scripts/simulate-az-failover.sh` (written here automatically) |
