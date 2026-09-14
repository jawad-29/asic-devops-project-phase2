# asic-devops-project-phase2
# ASIC DevOps Project – Phase 2

## Project Overview

This project demonstrates a practical DevOps workflow for a semiconductor/ASIC development environment.

The project combines:

* GitHub for source-code management
* Jenkins for CI/CD orchestration
* Icarus Verilog for RTL simulation
* Terraform for Infrastructure as Code
* Kubernetes (MicroK8s) for workload execution
* OpenROAD/OpenLane for EDA workload execution
* Prometheus for monitoring and alerting
* Grafana for visualization

The main objective is to demonstrate how semiconductor-related workloads can be integrated into an automated DevOps pipeline.

---

## Architecture

```text
Developer
   |
   | git push
   v
GitHub
   |
   | HTTPS checkout
   v
Jenkins
   |
   +-----------------------------+
   |                             |
   v                             v
RTL Simulation              Design Quality Checks
   |                             |
   +-------------+---------------+
                 |
                 v
          Terraform Init
                 |
                 v
        Terraform Validate
                 |
                 v
          Terraform Plan
                 |
                 v
          Manual Approval
                 |
                 v
         Terraform Apply
                 |
                 v
             Kubernetes
                 |
          +------+------+
          |             |
          v             v
     Namespace      OpenROAD Job
                         |
                         v
                  kube-state-metrics
                         |
                         v
                     Prometheus
                      /       \
                     /         \
                    v           v
               Grafana      Alertmanager
```

---

## Repository Structure

```text
asic-devops-project-phase2/
|
├── src/
│   └── counter.v
|
├── TestBench/
│   └── counter_tb.v
|
├── scripts/
│   ├── simulate.sh
│   └── design_quality_check.sh
|
├── terraform/
│   ├── main.tf
│   └── .terraform.lock.hcl
|
├── Jenkinsfile
├── .gitignore
└── README.md
```

---

## CI/CD Pipeline

The Jenkins pipeline performs the following stages:

### 1. Checkout

Jenkins retrieves the source code from the public GitHub repository using HTTPS.

### 2. Verify Environment

The pipeline verifies that Jenkins can access the required tools:

* Git
* Terraform
* Icarus Verilog
* kubectl

### 3. RTL Simulation

The pipeline executes:

```bash
./scripts/simulate.sh
```

The counter RTL and testbench are compiled and simulated.

The expected verification result is:

```text
PASS: Reset check
PASS: Counter reached expected value = 5
SIMULATION PASSED
```

### 4. Design Quality Checks

The pipeline executes:

```bash
./scripts/design_quality_check.sh
```

The script verifies:

* RTL source exists
* Testbench exists
* Reset path exists
* Counter output width is correct

### 5. Terraform Init

Jenkins initializes Terraform and uses the Kubernetes provider.

### 6. Terraform Validate

Jenkins verifies that the Terraform configuration is syntactically and structurally valid.

### 7. Terraform Plan

Terraform compares the desired configuration with the actual Kubernetes infrastructure.

The plan is stored as:

```text
terraform/phase2.tfplan
```

### 8. Review and Approval

Jenkins displays the Terraform plan and pauses for human approval.

The deployment is not applied until the operator selects:

```text
Approve Apply
```

### 9. Terraform Apply

The approved Terraform plan is applied:

```bash
terraform apply -input=false phase2.tfplan
```

### 10. Post-Deployment Verification

Jenkins verifies:

* Kubernetes namespace exists
* OpenROAD Job exists
* Job completed
* OpenROAD pod exists
* Container exit code is `0`

A successful execution is reported as:

```text
OpenROAD execution confirmed successful.
```

---

## Terraform Managed Resources

Terraform manages the following resources:

```text
kubernetes_namespace_v1.semiconductor_devops
kubernetes_job_v1.openroad
kubernetes_manifest.openroad_job_alert
```

### Kubernetes Namespace

```text
semiconductor-devops-phase2
```

### OpenROAD Job

```text
openroad-eda-job
```

The workload uses:

```text
ghcr.io/the-openroad-project/openlane:1.0.2
```

The container executes:

```bash
/build/bin/openroad -version
```

This provides a simple and reproducible OpenROAD execution test.

---

## Terraform State

Terraform state is stored in the Jenkins-owned location:

```text
/var/lib/jenkins/terraform-state/phase2/terraform.tfstate
```

This keeps the state separate from the developer's personal project directory.

The Jenkins workspace is:

```text
/var/lib/jenkins/workspace/ASIC-DevOps-CI-phase2
```

This also avoids filesystem permission problems between the normal Linux user and the Jenkins service account.

---

## Monitoring

The project uses the existing Kubernetes observability stack.

Monitoring components include:

```text
Prometheus
Grafana
Alertmanager
kube-state-metrics
node-exporter
```

The project adds a Terraform-managed Prometheus rule:

```text
openroad-job-alert
```

The alert is:

```text
OpenROADJobFailed
```

It monitors:

```promql
kube_job_status_failed{
  namespace="semiconductor-devops-phase2",
  job_name="openroad-eda-job"
} > 0
```

The alert has:

```text
severity = critical
```

The Prometheus Operator has validated the rule.

---

## Grafana Dashboard

A dedicated Grafana dashboard was created:

```text
ASIC DevOps Phase 2
```

Current panels include:

### OpenROAD Job Failures

Metric:

```promql
kube_job_status_failed{
  namespace="semiconductor-devops-phase2",
  job_name="openroad-eda-job"
}
```

Current healthy value:

```text
0
```

### OpenROAD Job Status

Metric:

```promql
kube_job_status_succeeded{
  namespace="semiconductor-devops-phase2",
  job_name="openroad-eda-job"
}
```

Current successful completion count:

```text
1
```

---

## Kubernetes Verification Commands

Check the deployed resources:

```bash
microk8s kubectl get jobs,pods -n semiconductor-devops-phase2
```

Check the Prometheus rule:

```bash
microk8s kubectl get prometheusrule -n semiconductor-devops-phase2
```

Describe the alert rule:

```bash
microk8s kubectl describe prometheusrule openroad-job-alert \
  -n semiconductor-devops-phase2
```

Check the Terraform-managed state:

```bash
sudo -u jenkins bash -lc \
'cd /var/lib/jenkins/workspace/ASIC-DevOps-CI-phase2/terraform && terraform state list'
```

Expected resources:

```text
kubernetes_job_v1.openroad
kubernetes_manifest.openroad_job_alert
kubernetes_namespace_v1.semiconductor_devops
```

---

## Key DevOps Concepts Demonstrated

This project demonstrates:

### Continuous Integration

Code changes trigger:

```text
Checkout
→ RTL Simulation
→ Quality Checks
```

### Infrastructure as Code

Terraform defines Kubernetes infrastructure declaratively.

### Continuous Delivery

Jenkins performs:

```text
Plan
→ Review
→ Approval
→ Apply
```

### Automated Verification

Jenkins verifies the deployed Kubernetes workload after Terraform execution.

### Monitoring and Observability

Kubernetes workload state is exposed through kube-state-metrics and queried by Prometheus.

Grafana provides visualization, while Prometheus evaluates the alerting rule.

---

## Important Design Decisions

### Public GitHub Repository

The repository is public, so Jenkins checks it out over HTTPS without requiring a GitHub credential.

### Jenkins-Owned Workspace

Jenkins uses:

```text
/var/lib/jenkins/workspace/
```

instead of the developer's `/home/j/...` directory.

### Jenkins-Owned Terraform State

Terraform state is stored under:

```text
/var/lib/jenkins/terraform-state/phase2/
```

so Jenkins remains the deployment owner.

### Separate Phase 2 Namespace

Phase 2 uses:

```text
semiconductor-devops-phase2
```

instead of the Phase 1 namespace.

This prevents Phase 2 Terraform from taking ownership of existing Phase 1 resources.

---

## End-to-End Workflow

```text
Git Push
   |
   v
GitHub
   |
   v
Jenkins Checkout
   |
   v
RTL Simulation
   |
   v
Design Quality Checks
   |
   v
Terraform Init
   |
   v
Terraform Validate
   |
   v
Terraform Plan
   |
   v
Manual Approval
   |
   v
Terraform Apply
   |
   v
Kubernetes
   |
   +--> semiconductor-devops-phase2
   |
   +--> openroad-eda-job
   |
   +--> openroad-job-alert
             |
             v
         Prometheus
             |
             v
          Grafana
```

---

## Project Status

Current Phase 2 implementation:

```text
GitHub integration                  Complete
Jenkins CI pipeline                 Complete
RTL simulation                      Complete
Design quality checks               Complete
Terraform IaC                       Complete
Kubernetes deployment               Complete
OpenROAD execution                  Complete
Prometheus monitoring               Complete
Prometheus alert rule               Complete
Grafana dashboard                   Complete
Post-deployment verification        Complete
```

## Project Goal

The final goal is to demonstrate a simple, reproducible DevOps workflow for semiconductor-oriented development:

```text
Source Code
     ↓
CI Testing
     ↓
Infrastructure as Code
     ↓
Controlled Deployment
     ↓
Kubernetes Workload
     ↓
Monitoring and Alerting
```

This provides a practical foundation for explaining how DevOps practices can support semiconductor and ASIC development workflows.

````

Save with:

**Ctrl+O → Enter → Ctrl+X**

Then run:

```bash
git diff --check
````

and:

```bash
git status
```

Since the README is currently very small, this should result in just:

```text
modified: README.md
```

After that, we'll commit the documentation and do one final repository check.

