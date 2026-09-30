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

# Stop managing the existing OpenROAD Job through Terraform
# without deleting the real Kubernetes Job.
removed {
  from = kubernetes_job_v1.openroad

  lifecycle {
    destroy = false
  }
}

resource "kubernetes_namespace_v1" "semiconductor_devops" {
  metadata {
    name = "semiconductor-devops-phase2"
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

              expr = "kube_job_status_failed{namespace=\"semiconductor-devops-phase2\",job_name=~\"openroad-eda-job-.*\"} > 0"

              for = "1m"

              labels = {
                severity = "critical"
              }

              annotations = {
                summary     = "OpenROAD Kubernetes Job failed"
                description = "An OpenROAD EDA Job has reported one or more failures."
              }
            }
          ]
        }
      ]
    }
  }
}
