![Platform](https://img.shields.io/badge/Platform-Kubernetes-blue)
![CI/CD](https://img.shields.io/badge/CI/CD-Jenkins-red)
![Security](https://img.shields.io/badge/Security-Cosign-green)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus-orange)
![Automation](https://img.shields.io/badge/Automation-Bash-yellow)

# Project: Production-Grade DevSecOps Platform, AWS Ready.

## One-Command Automated DevSecOps Platform

This project implements a fully automated, production-style DevSecOps platform that provisions infrastructure, configures Kubernetes, deploys monitoring, and verifies system health using a single bootstrap command.

#### _Automatic TLS Certificate Generation_

_- NOTE: This platform automatically generates required TLS certificates during bootstrap. No manual certificate creation is required just run bootstrap.sh given below._

```bash
./bootstrap.sh
```

This platform demonstrates real-world DevOps engineering practices including:

- Infrastructure automation
- Kubernetes cluster lifecycle management
- Secure software supply chain (Trivy, SBOM, Cosign)
- Private TLS container registry
- CI/CD pipeline automation with Jenkins
- Monitoring and observability using Prometheus and Grafana
- Idempotent bootstrap architecture

The entire environment can be provisioned, stopped, and restarted safely using automation scripts.


# Project Overview

### PROJECT: V2.0 - Feb 15, 2026

- `Git Push` -> `Webhook` -> `Secret Scan` -> `Build` -> `Image Scan` -> `SBOM Generation` -> `Image Signing & Verify` -> `K8s Deploy` -> `Monitoring and Observability`.

### Secure Software Supply Chain Flow of V2

1. Developer pushes code to Gitea
2. Gitea triggers Jenkins pipeline
3. Jenkins scans source for secrets
4. Jenkins builds container image
5. Jenkins scans image for vulnerabilities
6. Jenkins generates SBOM
7. Jenkins signs image using Cosign
8. Jenkins verifies image signature
9. Jenkins pushes image to private TLS registry
10. Kubernetes pulls signed image using trusted registry
11. Kubernetes deploys immutable image digest

---

### PROJECT: V1.0 - Oct 18, 2025

- `Git Push` -> `Webhook` -> `Build image` -> `k3s Cluster Pulls` ->  `Deploy pods` -> `Monitoring and Observability`.

### Supply Chain Flow of V1

1. Developer pushes code to Gitea
2. Gitea triggers Jenkins pipeline
3. Jenkins builds container image
4. Jenkins pushes image to insecure local http registry.
5. Kubernetes pulls image using local registry
6. Kubernetes deploys.

## Lessons Learned

This project was an intensive exercise in system integration and debugging. Key takeaways include:
*   **Immutability of Infrastructure:** When a local cluster becomes "poisoned" with bad networking or security configs, it is faster and more reliable to delete and recreate it than to patch it.
*   **Explicit Trust is Mandatory:** In a private, secure environment, "automatic" trust doesn't exist. Every communication hop (Jenkins -> Registry -> K8s) requires explicit certificate injection and verification.
*   **Pathing and Quoting in WSL:** Windows file paths with spaces require strict quoting to prevent tools like `k3s` from failing to find volumes.

#### _IMPORTANT (WSL USERS)_

- For best reliability, clone and run the project inside WSL filesystem:

**Correct**:
```bash
~/projects/devsecops-platform
```
Avoid:
```bash
 /mnt/c/Users/.../Downloads/devsecops-platform
 ```
 
- This avoids filesystem permission issues caused by Windows mounts.

## Table of Contents

- [Project Overview](#project-overview)
  - [Secure Software Supply Chain Flow of V2](#secure-software-supply-chain-flow-of-v2)
  - [Supply Chain Flow of V1](#supply-chain-flow-of-v1)
  - [Lessons Learned](#lessons-learned)

- [About Repository](#about-repository)
  - [Core Concepts and Skills Demonstrated](#core-concepts--skills-demonstrated)
  - [Architecture Diagram](#architecture-diagram)
  - [End-to-End Trust Architecture](#end-to-end-trust-architecture)
  - [Component Responsibilities](#component-responsibilities)
  - [Network Architecture](#network-architecture)
  - [Private Registry Security](#private-registry-security)
  - [Immutable Deployment Strategy](#immutable-deployment-strategy)

- [Quick Start (Automated Setup - Recommended)](#quick-start-automated-setup---recommended)
  - [Automation Scripts Overview](#automation-scripts-overview)
  - [Automated Provisioning Architecture](#automated-provisioning-architecture)

- [Manual Setup (Advanced / Educational)](#manual-setup-advanced--educational)
  - [Prerequisites](#prerequisites)
  - [Step 1: Launch Core Infrastructure](#step-1-launch-the-core-infrastructure)
  - [Step 2: Create Kubernetes Cluster](#step-2-create-the-kubernetes-cluster)
  - [Step 3: One-Time Service Setup Gitea](#step-3-one-time-service-setup-gitea)
  - [Step 4: Jenkins First-Time Setup](#step-4-jenkins-first-time-setup)
  - [Step 5: Create and Configure Kubernetes Credentials](#step-5-create-and-configure-kubernetes-credentials)
  - [Step 6: Creating custom Kubeconfig](#step-6-creating-custom-kubeconfig-jenkinsyaml-file)
  - [Step 7: Configure the CI/CD Pipeline](#step-7-configure-the-cicd-pipeline)
  - [Step 8: Deploy the Monitoring Stack](#step-8-deploy-the-monitoring-stack)
  - [Step 9: Testing the Pipeline](#step-9-testing-the-pipeline)

- [Appendix A: Standalone Terraform Demonstration](#appendix-a-standalone-terraform-demonstration)
- [License](#license)


## About Repository

This repository contains the Infrastructure as Code for a complete, local DevOps ecosystem that simulates a modern, secure software delivery lifecycle. Using Docker Compose, it orchestrates a suite of best-in-class open-source tools to automatically build, test, secure, and deploy a containerized application to a multi-node Kubernetes cluster.

The platform is designed as a hands-on learning environment to master advanced concepts including native TLS, container security, pipeline-as-code, and Infrastructure as Code (IaC).

**Companion Application Repository:** [https://github.com/YogeshT22/sample-flask-app](https://github.com/YogeshT22/sample-flask-app)

**Jump to how to install and run section quickly by if you hate reading!!**: [How to Run This Platform](#how-to-run-this-platform)


## Core Concepts & Skills Demonstrated

*   **DevSecOps Pipeline Design:** Implemented a full, multi-stage pipeline with a "Security First" approach: 
	- `Git Push` -> `Webhook` -> `Secret Scan` -> `Build` -> `Image Scan` -> `SBOM Generation` -> `Image Signing & Verification` -> `Deploy`.
*   **Infrastructure as Code (IaC):**
    *   **Docker Compose:** Used for the orchestration of the core CI/CD toolchain.
    *   **Terraform:** Includes a standalone demonstration of the core Terraform workflow for infrastructure provisioning.
*   **Secure Infrastructure:**
    *   **Native TLS Registry:** Deployed a private Docker Registry secured with HTTPS using locally trusted certificates generated by `mkcert`.
    *   **End-to-End Trust:** Engineered a "Circle of Trust" where all components (Docker daemon, Jenkins, K3s nodes) are configured to trust the custom root CA, eliminating the need for insecure flags.
*   **Container Orchestration:** Deployed and managed applications on a **Kubernetes (K3s)** cluster, using `Deployments`, `Services`, and `Ingress`.
*   **Software Supply Chain Security:**
    *   **Vulnerability Scanning:** Integrated **Trivy** for both filesystem (pre-build) and container image (post-build) scanning.
    *   **SBOM Generation:** Created a CycloneDX Software Bill of Materials for every build.
    *   **Image Integrity:** Used **Cosign** to cryptographically sign and verify container images, ensuring they are not tampered with between build and deployment.
*   **Observability & Monitoring:** Deployed **Prometheus** and **Grafana** using a **Helm** chart to collect and visualize real-time metrics.



## Architecture Diagram

![Architecture Diagram](assets/arch.png)


## End-to-End Trust Architecture

This platform implements a complete cryptographic trust chain across the software supply chain:

1. **Certificate Authority (CA)**
   - A custom Root CA is generated using `mkcert`.
   - This CA signs the private Docker Registry TLS certificate.

2. **Trusted Components**
   The Root CA is explicitly injected into:

   - Docker daemon
   - Jenkins container
   - Kubernetes (k3s) nodes

3. **Registry Trust**
   This allows all components to securely communicate with the private registry without insecure flags.

4. **Image Integrity**
   - Images are signed using Cosign private key.
   - Public key (cosign.pub) is stored in repository.
   - Jenkins verifies image signatures before deployment.

5. **Immutable Deployment**
   Kubernetes deploys images using immutable SHA256 digest instead of mutable tags.

This ensures:

- Image authenticity
- Registry authenticity
- Deployment integrity
- End-to-end supply chain security



## Component Responsibilities

| Component | Role |
|--------|------|
| Gitea | Source code management and webhook trigger |
| Jenkins | CI/CD orchestration, build, scan, sign, deploy |
| Docker Registry | Secure image storage with TLS |
| Trivy | Secret scanning and vulnerability scanning |
| Cosign | Image signing and verification |
| Kubernetes (k3s) | Container orchestration |
| Prometheus | Metrics collection |
| Grafana | Metrics visualization |
| mkcert | Local certificate authority |

## Network Architecture

All services run inside an isolated Docker bridge network:

big-project-2-cicd-pipeline_cicd-net

This allows secure internal communication using container DNS names:

- gitea-server:3000
- jenkins-server:8080
- local-docker-registry:5000

Kubernetes nodes join the same network via k3s, allowing direct secure image pulls.

No external insecure registry exposure is required.

## Private Registry Security

The private Docker registry is secured using:

- TLS encryption
- Custom Root CA trust
- Internal Docker network isolation

Images are never pulled from public insecure registries during deployment.

This simulates enterprise private registry environments such as:

- AWS ECR
- Azure ACR
- Google Artifact Registry
- Harbor

## Immutable Deployment Strategy

Instead of deploying using mutable tags (latest, v1, etc), this platform deploys using immutable SHA256 image digests:

example:

local-docker-registry:5000/sample-flask-app@sha256:abcd1234...

This prevents:

- image tampering
- tag overwrite attacks
- inconsistent deployments

## Quick Start (Automated Setup - Recommended)

This platform can be fully provisioned using a single command. The bootstrap system automatically creates the infrastructure, configures Kubernetes, deploys monitoring, and verifies platform health.

### Step 1: Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/big-project-2-cicd-pipeline.git
cd big-project-2-cicd-pipeline
```

### Step 2: Run the bootstrap script

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This script will automatically:

* Start Docker infrastructure (Gitea, Jenkins, Private Registry)
* Wait for all services to become ready
* Create or recover the Kubernetes cluster
* Configure Kubernetes credentials for CI/CD
* Deploy Prometheus and Grafana monitoring stack
* Verify full platform health and connectivity

No manual setup steps are required.

---

### Platform Access URLs

After successful bootstrap, access the services:

| Service     | URL                                              |
| ----------- | ------------------------------------------------ |
| Gitea       | [http://localhost:8081](http://localhost:8081)   |
| Jenkins     | [http://localhost:8080](http://localhost:8080)   |
| Grafana     | [http://localhost:30900](http://localhost:30900) |
| Application | [http://localhost:8082](http://localhost:8082)   |

---

### Stop the Platform Safely

To stop all infrastructure without deleting data:

```bash
./stop-platform.sh
```

This safely stops:

* Kubernetes cluster
* Docker containers

All data, registry images, and configurations are preserved.

---

## Automation Scripts Overview

The platform uses modular, production-style infrastructure automation scripts located in the `scripts/` directory.

Each script has a single responsibility and is safe to rerun (idempotent).

| Script                     | Purpose                                              |
| -------------------------- | ---------------------------------------------------- |
| 01-start-infrastructure.sh | Starts Docker services                               |
| 02-wait-for-services.sh    | Waits until Gitea, Jenkins, and Registry are ready   |
| 03-create-cluster.sh       | Creates or recovers Kubernetes cluster               |
| 04-configure-kubernetes.sh | Configures Kubernetes service account and kubeconfig |
| 05-deploy-monitoring.sh    | Deploys Prometheus and Grafana using Helm            |
| 06-verify-platform.sh      | Verifies full platform functionality                 |
| stop-platform.sh           | Safely stops platform infrastructure                 |
| bootstrap.sh               | Orchestrates full platform provisioning              |

---

## Automated Provisioning Architecture

The platform follows a production-grade bootstrap model:

1. Infrastructure startup
2. Service readiness verification
3. Kubernetes cluster provisioning
4. Trust and credential configuration
5. Monitoring deployment
6. Platform verification

This ensures the platform is:

* Fully reproducible
* Safe to rerun
* Resistant to partial failures
* Suitable for real DevOps workflows

---

## Manual Setup (Advanced / Educational)

Manual setup instructions are provided below for educational purposes and to demonstrate the underlying infrastructure configuration process.

For normal usage, the automated bootstrap method is recommended.


**Prerequisites:**

- **Docker Desktop** with WSL2 integration enabled.
- **WSL2** with a Linux distribution (e.g., Ubuntu).
- **Helm** and **k3s** installed inside your WSL environment.



### Step 1: Launch the Core Infrastructure

- Navigate to this project's directory and launch the Gitea, Jenkins, and Registry services.

```bash
docker-compose up --build -d
```

_Wait 2-3 minutes for all services to initialize before proceeding._

---

### Step 2: Create the Kubernetes Cluster

- Use k3s to create a multi-node cluster connected to the CI/CD network and configured to trust the local registry.

- **Note 1A** 
	- **If registries.yaml doesnt exist create one and copy paste below code.** 
	- if registries.yaml does exist then -> go to **Note 1b**.

```yaml
#Create a registries.yaml in project root and paste the below code in that file and save it.
mirrors:
  "local-docker-registry:5000":
    endpoint:
      - "https://local-docker-registry:5000"

configs:
  "local-docker-registry:5000":
    tls:
      ca_file: /usr/local/share/ca-certificates/my-root-ca.crt
```

- **Note 1B** - Now run the code config given below to create a create a multi-node cluster.

```bash
k3d cluster create devops-cluster \
  --api-port 6550 \
  -p "8082:80@loadbalancer" \
  --network big-project-2-cicd-pipeline_cicd-net \
  --registry-config registries.yaml \
  --volume "$(pwd)/certs/rootCA.crt:/usr/local/share/ca-certificates/my-root-ca.crt@server:*" \
  --volume "$(pwd)/certs/rootCA.crt:/usr/local/share/ca-certificates/my-root-ca.crt@agent:*"
```

---

### Step 3: One-Time Service Setup Gitea

Perform the initial setup for Gitea.

1. Open your browser to `http://localhost:8081`.
2. On the initial configuration page, it is critical to set the following: 
	- Database Type: `SQLite3` (default is fine). 
	- Server Domain: `gitea-server` 
	- Gitea Base URL: `http://gitea-server:8081/`
   (This ensures Jenkins can find Gitea using its service name on the Docker network).

3. Expand "Administrator Account Settings" and create your admin user.
4. Click `"Install Gitea"` and log in.
5. Create a new public repository named `sample-flask-app`.
6. Follow the instructions on the Gitea page to push your local sample-flask-app code to this new repository.
	- _creating new remote like `git remote add gitea http://admin:admin localhost:8081/admin/sample-flask-app.git`_

---

### Step 4: Jenkins First-Time Setup

- Unlock Jenkins: Get the initial admin password from the logs:

```bash
docker logs jenkins-server
```

1. Go to `http://localhost:8080`, paste the password, and continue.
2. Install Plugins: Select "**Install suggested plugins**".
3. After the initial install, go to **Manage Jenkins -> Plugins -> Available plugins, search for and install Docker Pipeline.**
4. Set Jenkins URL: Go to **Manage Jenkins -> System.** In the Jenkins Location section, set the "Jenkins URL" to `http://jenkins-server:8080/`. Click Save.
   (This is crucial for webhook integrations to work correctly).
5. Create Jenkins API Token:
   - Click or Hover near your username (top right) -> Settings.
   - Find the "API Token" section and click "Add new Token".
   - Name it (e.g., gitea-webhook-token) and click Generate.
   - **Copy the generated token and save it.** You will not be shown it again.

---

### Step 5: Create and Configure Kubernetes Credentials

Before creating the Jenkins job, you must provide Jenkins with the credentials to access your K3s cluster.

_(go to application folder)_
1. **Apply the Service Account manifests** from the `sample-flask-app` repository to your cluster:

   ```bash
   kubectl apply -f k8s/service-account.yaml
   kubectl apply -f k8s/jenkins-token-secret.yaml
   ```

2. **Generate a custom `kubeconfig.yaml` file.** This involves getting your cluster's CA certificate, and the Service Account Token.
3. **Upload this `kubeconfig.yaml` file** to Jenkins as a "Secret file" credential with the ID `kubeconfig-sa`.

_Below steps to get CA certificate and Service account token._

---

### Step 6: Creating custom Kubeconfig-jenkins.yaml file

#### Guide: How to Create the kubeconfig-jenkins.yaml File

- This file is the key that allows Jenkins to securely authenticate with your Kubernetes cluster using the dedicated jenkins-admin Service Account. You will construct this file by gathering four pieces of dynamic information from your running environment.


---

#### Prerequisites

- Your k3s cluster is running.

- You have already applied the service-account.yaml and jenkins-token-secret.yaml manifests to your cluster.



### Step 6.A: Get the Cluster's Certificate Authority (CA)

- This is the public certificate that your cluster uses to prove its identity.

```bash
# Get the full kubeconfig from k3s
k3d kubeconfig get devops-cluster
```

- From the YAML output, find the **certificate-authority-data field** under clusters:
  - Copy the entire long, single-line string of encoded text.
  - It will look like LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...

### Step 6.B: Get the Jenkins Service Account Token

This is the "password" for the jenkins-admin user we created inside Kubernetes.

```bash
# This command gets the token from the secret we created
kubectl get secret jenkins-admin-token -o jsonpath='{.data.token}' | base64 --decode
```

This will output another very long string of characters starting with ey.... Copy this entire token.

#### Step 6.C: Assemble the kubeconfig-jenkins.yaml File

Now, create a new, empty file named kubeconfig-jenkins.yaml and paste the following template into it.

Template:

```yaml
apiVersion: v1
kind: Config
clusters:
  - name: k3d-devops-cluster-devops-cluster
    cluster:
      server: https://host.docker.internal:6550
      certificate-authority-data: YOUR BASE64_CA
users:
  - name: jenkins-admin
    user:
      token: SERVICE_ACCOUNT_TOKEN (starting with ey...)
contexts:
  - name: k3d-devops-cluster
    context:
      cluster: k3d-devops-cluster
      user: jenkins-admin
      namespace: default
current-context: k3d-devops-cluster
```

Fill in the placeholders using the two pieces of information(CA data and Service TOKEN) you just collected.


- You now have the complete and correct `kubeconfig-jenkins.yaml` file. 
- The final step is to upload this file to the Jenkins credentials store as a "Secret file" with the ID `kubeconfig-sa`.

---

### Step 7: Configure the CI/CD Pipeline

1. Create the Jenkins Job:

   - In Jenkins, click `"New Item"`.
   - Name: flask-app-pipeline, select `"Pipeline"`, and click OK.
   - Scroll down to the "Pipeline" section and configure it as follows:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `http://gitea-server:3000/YOUR_GITEA_USERNAME/sample-flask-app.git` (replace GITEA Username with yours)
     - Branch Specifier: `\*/main`
   - Click **Save**.

2. Configure the **Gitea Webhook**:

   - In Gitea, go to your 
	- `sample-flask-app repository` -> `Settings` -> `Webhooks`.
   - Click `"Add Webhook"` -> `"Gitea"`.
   - Target URL: Use the **following format or pattern below**, 
   - add your `Jenkins username` and the `API token` you just generated from **Step 4**. 
   - This authenticates the request and bypasses CSRF protection (Not recommended for production.).

- **Pattern** - <http://YOUR_JENKINS_USER:YOUR_API_TOKEN@jenkins-server:8080/job/flask-app-pipeline/build/>

- **Example:** <http://admin:11a22b33c44d55e66f77g88h99i@jenkins-server:8080/job/flask-app-pipeline/build>

- Leave other settings as default and click `"Add Webhook"`.

> **Important Note Again!** - Make sure u have Docker Plugin Installed in Jenkins. you must install the "Docker Pipeline" plugin to make it work!

**📦 How to Install Docker pipeline plugin (if not done):**

- Jenkins UI → Manage Jenkins → Plugins
- Go to Available
- Search for: Docker Pipeline
- Install and restart

> **Note:** This plugin is different from "Docker Commons Plugin" or "Docker plugin". You need Docker Pipeline, specifically.

---

### Step 8: Deploy the Monitoring Stack (Optional, but recommended)

- Use Helm to deploy Prometheus and Grafana into the cluster.

```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f helm-configs/prometheus-values.yaml

```

- Grafana accessible at `http://localhost:30900` (user/admin).
- _(Refer to helm-configs/prometheus-values.yaml for custom configuration.)_


---

### Step 9: Testing the Pipeline

You can now trigger the pipeline in two ways:

1. **Manually**: In Jenkins, go to the `flask-app-pipeline job` and click "Build Now".
2. **Automatically**: Make a code change in your local sample-flask-app, then git commit and git push it to Gitea. The pipeline should start within seconds.

After a successful run, you can view your deployed application at `<http://localhost:8082>`.


### Appendix A: Standalone Terraform Demonstration

This directory demonstrates the core workflow for infrastructure provisioning using Terraform to manage local Docker resources. **It is a standalone exercise**.

- **How to Run:**

```bash
    cd terraform-local-docker
    terraform init
    terraform plan
    terraform apply

```

- **To Clean Up:** `terraform destroy`
- **Directory:** `terraform-local-docker/`





## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
