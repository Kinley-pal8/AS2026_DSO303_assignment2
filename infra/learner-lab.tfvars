# AWS Academy Learner Lab profile (free). Use with: terraform apply -var-file=learner-lab.tfvars
# Learner Lab only allows us-east-1 / us-west-2 and does not allow creating IAM roles,
# so every service uses the pre-made LabRole. Services the lab may block are switched off;
# try turning any of them back on - if the apply fails with AccessDenied, switch it off again.
region                  = "us-east-1"
existing_role_name      = "LabRole"
use_customer_kms_key    = false # data still encrypted at rest with AWS-managed keys
enable_rds_proxy        = false # Lambdas connect straight to RDS with the Secrets Manager password
enable_waf              = false
enable_backup           = false
enable_flow_logs        = false
enable_ses              = false # e-mails are written to CloudWatch Logs (/aws/lambda/uniexam-prod-notifier)
nat_gateway_per_az      = false # one NAT saves lab credit; set true for the AZ-failure screenshot
db_multi_az             = true  # two-AZ database (rubric requirement)
create_buckets_with_cli = true  # lab SCP denies s3:GetBucketObjectLockConfiguration
enable_cloudfront       = false # lab denies cloudfront:CreateDistribution; API Gateway serves the SPA over HTTPS
