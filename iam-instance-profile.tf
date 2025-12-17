resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-${var.environment}-jenkins-instance-profile"
  role = aws_iam_role.jenkins.name
}

