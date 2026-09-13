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
resource "kubernetes_manifest" "openroad_job_alert" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"

    metadata = {
      name      = "openroad-job-alert"
      namespace = kubernetes_namespace_v1.semiconductor_devops.metadata[0].name

      labels = {
        release = "kube-prom-stack"
      }
    }

    spec = {
      groups = [
        {
          name = "openroad-job.rules"

          rules = [
            {
              alert = "OpenROADJobFailed"

              expr = "kube_job_status_failed{namespace=\"semiconductor-devops-phase2\",job_name=\"openroad-eda-job\"} > 0"

              for = "1m"

              labels = {
                severity = "critical"
              }

              annotations = {
                summary     = "OpenROAD Kubernetes Job failed"
                description = "The OpenROAD EDA Job has reported one or more failures."
              }
            }
          ]
        }
      ]
    }
  }
}
