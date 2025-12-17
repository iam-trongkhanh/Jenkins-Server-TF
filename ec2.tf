locals {
  jenkins_private_subnet_id = aws_subnet.private[tostring(var.jenkins_subnet_index)].id
}

resource "aws_instance" "jenkins" {
  ami                         = var.jenkins_ami_id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = local.jenkins_private_subnet_id
  key_name                    = var.jenkins_key_name
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  monitoring                  = var.enable_detailed_monitoring
  disable_api_termination     = var.disable_api_termination

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = var.jenkins_root_volume_size
    volume_type           = var.jenkins_root_volume_type
    encrypted             = true
    delete_on_termination = var.delete_root_volume_on_termination
  }

  user_data_base64 = filebase64("${path.module}/tools-install.sh")

  tags = {
    Name = "${var.project}-${var.environment}-jenkins"
    Role = "jenkins-master"
  }
}

