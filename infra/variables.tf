variable "project" {
  description = "Short project name used as a prefix for every resource."
  type        = string
  default     = "uniexam"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Primary AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR. Subnets are /24s carved from it."
  type        = string
  default     = "10.20.0.0/16"
}

variable "nat_gateway_per_az" {
  description = "One NAT gateway per AZ (true = survives an AZ loss) or a single shared one (cheaper for testing)."
  type        = bool
  default     = true
}

variable "db_instance_class" {
  description = "RDS instance class. Scale up (e.g. db.r6g.large) for real exam weeks."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "api_provisioned_concurrency" {
  description = "Pre-warmed API Lambda environments. Set to ~20 during exam week, 0 otherwise."
  type        = number
  default     = 0
}

variable "waf_rate_limit" {
  description = "Max requests per IP per 5 minutes. Kept high because a whole campus can share one NAT IP."
  type        = number
  default     = 20000
}

variable "ses_sender_email" {
  description = "Verified SES sender address for result / submission e-mails."
  type        = string
  default     = "noreply@example.com"
}

variable "alarm_email" {
  description = "E-mail address subscribed to CloudWatch alarms (empty = no subscription)."
  type        = string
  default     = ""
}

variable "initial_admin_email" {
  description = "If set, creates the first administrator in Cognito (an invite with a temporary password is e-mailed)."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Optional custom domain (e.g. exams.example.edu). Empty = use the CloudFront domain."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for domain_name (required if domain_name is set)."
  type        = string
  default     = ""
}

variable "cloudfront_price_class" {
  description = "CloudFront edge coverage. PriceClass_200 includes India and most of Asia."
  type        = string
  default     = "PriceClass_200"
}

variable "protect_data" {
  description = "Production safety: deletion protection on RDS/DynamoDB/Cognito, keep final snapshot, don't force-delete buckets. Set false for coursework so 'terraform destroy' works."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------- feature switches
# Everything defaults to the full production design. learner-lab.tfvars turns off what an
# AWS Academy Learner Lab account cannot create (it forbids creating IAM roles).

variable "existing_role_name" {
  description = "Use this existing IAM role (e.g. \"LabRole\" in Learner Lab) for every service instead of creating least-privilege roles."
  type        = string
  default     = ""
}

variable "use_customer_kms_key" {
  description = "Encrypt data with a customer-managed KMS key (false = AWS-managed keys / SSE-S3; still encrypted at rest)."
  type        = bool
  default     = true
}

variable "enable_rds_proxy" {
  description = "Put RDS Proxy (IAM auth) in front of PostgreSQL. False = Lambdas connect directly using the Secrets Manager password."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach AWS WAF to CloudFront."
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Create the AWS Backup vault/plan (5-year monthly backups)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "VPC flow logs to CloudWatch."
  type        = bool
  default     = true
}

variable "enable_ses" {
  description = "Send e-mail with SES. False = the notifier writes each e-mail to CloudWatch Logs instead (useful where SES is unavailable)."
  type        = bool
  default     = true
}

variable "db_multi_az" {
  description = "RDS Multi-AZ standby in the second AZ."
  type        = bool
  default     = true
}
