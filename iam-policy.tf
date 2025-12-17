locals {
  ecr_repository_arn_pattern = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
}

data "aws_iam_policy_document" "jenkins" {
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"] # Required by AWS for GetAuthorizationToken
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:StartImageScan",
      "ecr:UploadLayerPart",
    ]
    resources = [local.ecr_repository_arn_pattern]
  }

  dynamic "statement" {
    for_each = length(var.eks_cluster_arns) > 0 ? [1] : []
    content {
      sid    = "EKSDescribe"
      effect = "Allow"
      actions = [
        "eks:DescribeCluster",
      ]
      resources = var.eks_cluster_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.artifact_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3ArtifactBucketsList"
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
      ]
      resources = var.artifact_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.artifact_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3ArtifactsRW"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObjectVersion",
        "s3:GetObjectVersion",
        "s3:PutObjectAcl",
      ]
      resources = [for arn in var.artifact_bucket_arns : "${arn}/*"]
    }
  }
}

resource "aws_iam_policy" "jenkins" {
  name        = "${var.project}-${var.environment}-jenkins-policy"
  description = "Scoped Jenkins permissions for ECR/EKS/S3"
  policy      = data.aws_iam_policy_document.jenkins.json
}

resource "aws_iam_role_policy_attachment" "jenkins_core" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_additional" {
  for_each   = toset(var.jenkins_additional_iam_policy_arns)
  role       = aws_iam_role.jenkins.name
  policy_arn = each.key
}

