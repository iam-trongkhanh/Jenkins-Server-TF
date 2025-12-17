data "aws_iam_policy_document" "jenkins_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name                 = "${var.project}-${var.environment}-jenkins-role"
  description          = "IAM role for Jenkins EC2 with scoped permissions"
  path                 = "/"
  assume_role_policy   = data.aws_iam_policy_document.jenkins_assume_role.json
  max_session_duration = 3600

  tags = {
    Name = "${var.project}-${var.environment}-jenkins-role"
  }
}

