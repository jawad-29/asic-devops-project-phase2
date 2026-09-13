terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.1"
    }
  }

  backend "local" {
    path = "/var/lib/jenkins/terraform-state/phase2/terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = "/var/lib/jenkins/.kube/config"
}
resource "kubernetes_namespace_v1" "semiconductor_devops" {
  metadata {
    name = "semiconductor-devops-phase2"
  }
}
