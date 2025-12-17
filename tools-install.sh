#!/bin/bash
# Bootstrap script for Jenkins host.
# Supports Amazon Linux 2/2023 (yum/dnf) and Ubuntu (apt) without guessing.
set -euo pipefail

exec > >(tee -a /var/log/user-data.log) 2>&1

ARCH="amd64"
SONAR_BASE="/var/opt/sonarqube"
SONAR_IMAGE="sonarqube:lts-community" # Explicit community edition

if command -v apt-get >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  echo "=== Detected Ubuntu/Debian. Updating base packages ==="
  apt-get update -y
  apt-get install -y ca-certificates curl wget unzip tar jq gnupg lsb-release apt-transport-https software-properties-common

  echo "=== Installing Docker ==="
  apt-get install -y docker.io
  systemctl enable --now docker

  echo "=== Installing Terraform from HashiCorp repo ==="
  curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" >/etc/apt/sources.list.d/hashicorp.list
  apt-get update -y
  apt-get install -y terraform

  echo "=== Installing Jenkins (LTS) ==="
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" >/etc/apt/sources.list.d/jenkins.list
  apt-get update -y
  apt-get install -y fontconfig openjdk-17-jdk jenkins

  echo "=== Installing Trivy ==="
  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main" >/etc/apt/sources.list.d/trivy.list
  apt-get update -y
  apt-get install -y trivy

else
  echo "=== Detected Amazon Linux (yum/dnf). Updating base packages ==="
  dnf update -y || yum update -y

  echo "=== Installing base tooling ==="
  dnf install -y git curl wget unzip tar jq shadow-utils yum-utils awscli || yum install -y git curl wget unzip tar jq shadow-utils yum-utils awscli

  echo "=== Installing Docker ==="
  dnf install -y docker || yum install -y docker
  systemctl enable --now docker

  echo "=== Installing Terraform from HashiCorp repo ==="
  rpm -qi hashicorp-release >/dev/null 2>&1 || yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
  dnf install -y terraform || yum install -y terraform

  echo "=== Installing Jenkins (LTS) ==="
  rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
  cat >/etc/yum.repos.d/jenkins.repo <<'EOF'
[jenkins]
name=Jenkins-stable
baseurl=https://pkg.jenkins.io/redhat-stable
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
EOF
  dnf install -y fontconfig java-17-openjdk jenkins || yum install -y fontconfig java-17-openjdk jenkins

  echo "=== Installing Trivy ==="
  rpm --import https://aquasecurity.github.io/trivy-repo/rpm/public.key
  cat >/etc/yum.repos.d/trivy.repo <<'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
gpgcheck=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
enabled=1
EOF
  dnf install -y trivy || yum install -y trivy
fi

echo "=== Installing kubectl (latest stable) ==="
KUBECTL_VERSION="$(curl -sL https://dl.k8s.io/release/stable.txt)"
curl -sL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

echo "=== Installing Helm 3 ==="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Adding Jenkins/ubuntu users to docker group ==="
if id jenkins >/dev/null 2>&1; then
  usermod -aG docker jenkins
fi
if id ubuntu >/dev/null 2>&1; then
  usermod -aG docker ubuntu
fi

echo "=== Deploying SonarQube (Docker) ==="
mkdir -p "${SONAR_BASE}/data" "${SONAR_BASE}/logs" "${SONAR_BASE}/extensions"
if ! docker ps -a --format '{{.Names}}' | grep -qw sonarqube; then
  docker run -d --name sonarqube \
    --restart unless-stopped \
    -p 9000:9000 -p 9092:9092 \
    -v "${SONAR_BASE}/data:/opt/sonarqube/data" \
    -v "${SONAR_BASE}/logs:/opt/sonarqube/logs" \
    -v "${SONAR_BASE}/extensions:/opt/sonarqube/extensions" \
    "${SONAR_IMAGE}"
else
  echo "SonarQube container already exists; skipping create."
fi

echo "=== Enabling and starting Jenkins ==="
systemctl enable jenkins
systemctl start jenkins

echo "Bootstrap complete."
