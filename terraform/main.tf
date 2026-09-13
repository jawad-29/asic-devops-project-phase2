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

resource "kubernetes_job_v1" "openroad" {
  metadata {
    name      = "openroad-eda-job"
    namespace = kubernetes_namespace_v1.semiconductor_devops.metadata[0].name
  }

  spec {
    backoff_limit = 1

    template {
      metadata {
        labels = {
          app = "openroad-eda"
        }
      }

      spec {
        restart_policy = "Never"

        container {
          name  = "openroad"
          image = "ghcr.io/the-openroad-project/openlane:1.0.2"

          command = [
            "/bin/bash",
            "-c",
            "/build/bin/openroad -version"
          ]
        }
      }
    }
  }
}
