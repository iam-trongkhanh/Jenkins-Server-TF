terraform {
  backend "s3" {
    bucket         = "__________ (S3 backend bucket name)"
    key            = "__________ (state object key, e.g., env/jenkins.tfstate)"
    region         = "__________ (AWS region for state backend)"
    dynamodb_table = "__________ (DynamoDB lock table name)"
    encrypt        = true
  }
}

