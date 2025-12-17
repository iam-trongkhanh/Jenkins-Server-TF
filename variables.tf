variable "aws_region" {
  description = "AWS region to deploy Jenkins."
  type        = string

  validation {
    condition     = length(var.aws_region) > 0
    error_message = "aws_region must be provided explicitly."
  }
}

variable "project" {
  description = "Project name for tagging and identification."
  type        = string
}

variable "environment" {
  description = "Environment identifier (e.g., dev, staging, prod)."
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for this deployment."
  type        = string
}

variable "additional_tags" {
  description = "Optional additional tags to merge into all supported resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the Jenkins VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR notation."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (used for NAT/bastion/egress)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR must be provided."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets where Jenkins will run."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) > 0 && length(var.private_subnet_cidrs) == length(var.public_subnet_cidrs)
    error_message = "Provide at least one private subnet CIDR and match the number of public subnets."
  }
}

variable "availability_zones" {
  description = "Optional list of AZs to use. Leave empty to auto-select."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == length(var.public_subnet_cidrs)
    error_message = "When provided, availability_zones length must match subnet CIDR lists."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnet egress."
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to the Jenkins host (bastion/VPN/office only)."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "allowed_ssh_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}

variable "jenkins_ui_cidrs" {
  description = "CIDRs allowed to reach Jenkins UI (8080). Keep empty unless explicitly approved."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.jenkins_ui_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"
    ])
    error_message = "jenkins_ui_cidrs must be valid CIDRs and must not include 0.0.0.0/0."
  }
}

variable "jenkins_ui_source_security_group_ids" {
  description = "Security group IDs allowed to reach Jenkins UI (e.g., ALB/ingress)."
  type        = list(string)
  default     = []
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins."
  type        = string
}

variable "jenkins_ami_id" {
  description = "AMI ID for Jenkins host (Amazon Linux 2 or AL2023 preferred)."
  type        = string

  validation {
    condition     = length(var.jenkins_ami_id) > 0
    error_message = "jenkins_ami_id must be explicitly set; do not use implicit lookups."
  }
}

variable "jenkins_root_volume_size" {
  description = "Root EBS volume size (GB) sized for Docker/Jenkins workloads."
  type        = number

  validation {
    condition     = var.jenkins_root_volume_size >= 50
    error_message = "Use at least 50 GB to accommodate Jenkins home and Docker layers."
  }
}

variable "jenkins_root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "delete_root_volume_on_termination" {
  description = "If false, preserves Jenkins root volume to avoid accidental data loss."
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Protect the instance from API termination."
  type        = bool
  default     = true
}

variable "jenkins_key_name" {
  description = "SSH key pair name for Jenkins instance access."
  type        = string
  default     = null
}

variable "jenkins_subnet_index" {
  description = "Index of private subnet list to place Jenkins into."
  type        = number
  default     = 0

  validation {
    condition     = var.jenkins_subnet_index >= 0 && var.jenkins_subnet_index < length(var.private_subnet_cidrs)
    error_message = "jenkins_subnet_index must reference an existing private subnet."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring on the instance."
  type        = bool
  default     = false
}

variable "artifact_bucket_arns" {
  description = "S3 bucket ARNs Jenkins may read/write artifacts to."
  type        = list(string)
  default     = []
}

variable "eks_cluster_arns" {
  description = "EKS cluster ARNs Jenkins needs to describe/interact with."
  type        = list(string)
  default     = []
}

variable "jenkins_additional_iam_policy_arns" {
  description = "Optional additional IAM policy ARNs to attach to the Jenkins role."
  type        = list(string)
  default     = []
}

