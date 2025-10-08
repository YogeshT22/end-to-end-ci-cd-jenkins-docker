# Project: End-to-End CI/CD Pipeline Platform with Kubernetes
### FINAL PROJECT VERSION: V1 - OCT 08, 2025

This repository contains the Infrastructure as Code for a complete, local DevOps ecosystem built with Docker. It showcases a full software lifecycle, from infrastructure provisioning with **Terraform**, to CI/CD with **Gitea** and **Jenkins**, to container orchestration with **Kubernetes (K3s)**.

This platform is designed to automatically build, test, secure, and deploy a containerized application to Kubernetes. The entire system demonstrates a real-world, end-to-end DevOps workflow, including automated webhook triggers, artifact management, observability with **Prometheus & Grafana**.

**Companion Application Repository:** [https://github.com/YogeshT22/sample-flask-app](https://github.com/YogeshT22/sample-flask-app)

---

## Core Concepts & Skills Demonstrated

- **Infrastructure as Code (IaC):**
  - **Terraform:** Used for infrastructure provisioning. This project includes a local demonstration of the core Terraform workflow (`init`, `plan`, `apply`) to manage Docker containers as code.
  - **Docker Compose:** Used for multi-service orchestration of the core CI/CD toolchain.
- **CI/CD Pipeline Design:** Implemented a full, multi-stage pipeline: `Git Push` -> `Webhook` -> `Build` -> `Push to Registry` -> `Security Scan` -> `Deploy`.
- **Container Orchestration:** Deployed and managed applications on a **Kubernetes (K3s)** cluster, using `Deployments`, `Services`, and `Ingress`.
- **Observability & Monitoring:** Deployed **Prometheus** and **Grafana** using a **Helm** chart to collect and visualize real-time metrics from the Kubernetes cluster.
- **Complex Debugging:** Systematically diagnosed and solved real-world issues across networking (Docker/WSL/Kubernetes), security (CSRF, TLS), and application configuration.
- **Kubernetes Authentication:** Implemented a secure and professional authentication pattern by creating a dedicated **Kubernetes Service Account** for Jenkins, using its token to authenticate API requests from the CI/CD pipeline.

---

## Architecture Diagram

![Architecture-diagram](src/arch-diagram1.png)

---

## How to Run This Platform

**Prerequisites:**

- **Docker Desktop** with WSL2 integration enabled.
- **WSL2** with a Linux distribution (e.g., Ubuntu).
- **Helm** and **k3d** installed inside your WSL environment.

---

### Step 1: One-Time Docker Configuration

- Configure your Docker daemon to trust the local registry by adding **`"insecure-registries": ["localhost:5000"]`** to the Docker Engine JSON configuration in Docker Desktop settings and restarting.

- Use the code below (JSON):

```bash
"insecure-registries": [
  "localhost:5000"
]
```

---

### Step 2: Launch the Core Infrastructure

- Navigate to this project's directory and launch the Gitea, Jenkins, and Registry services.

```bash
docker-compose up --build -d
```

_Wait 2-3 minutes for all services to initialize before proceeding._

---

### Step 3: Create the Kubernetes Cluster

- Use k3d to create a multi-node cluster connected to the CI/CD network and configured to trust the local registry.

- **Note 1a** - If registries.yaml doesnt exist create one and copy paste below code. if registries.yaml does exist then -> go to **Note 1b**.

```yaml
#Create a registries.yaml in project root and paste the below code in that file and save it.
mirrors:
  "localhost:5000":
    endpoint:
      - http://local-docker-registry:5000
```

- **Note 1b** - Now run the code below to create a create a multi-node cluster. (the code below expect registries.yaml file to be existing in your project root folder).

```bash
# Create the registries.yaml file as described in the project
k3d cluster create devops-cluster -p "8082:80@loadbalancer" --network big-project-2-cicd-pipeline_cicd-net --registry-config registries.yaml
```

---

### Step 4a: One-Time Service Setup Gitea

Perform the initial setup for Gitea (setting domain to gitea-server) and Jenkins (unlocking, installing plugins, setting URL to <http://jenkins-server:8080/>, and creating an API token).

1. Open your browser to <http://localhost:8081>.
2. On the initial configuration page, it is critical to set the following: - Database Type: SQLite3 (default is fine). - Server Domain: gitea-server - Gitea Base URL: <http://gitea-server:8081/>
   (This ensures Jenkins can find Gitea using its service name on the Docker network).

3. Expand "Administrator Account Settings" and create your admin user.
4. Click "Install Gitea" and log in.
5. Create a new public repository named sample-flask-app.
6. Follow the instructions on the Gitea page to push your local sample-flask-app code to this new repository.
_creating new remote like git remote add gitea http://admin:admin@localhost:8081/admin/sample-flask-app.git works!_

---

### Step 4b: Jenkins First-Time Setup

- Unlock Jenkins: Get the initial admin password from the logs:

```bash
docker logs jenkins-server

```

1. Go to <http://localhost:8080>, paste the password, and continue.
2. Install Plugins: Select **"Install suggested plugins"**. After the initial install, go to **Manage Jenkins -> Plugins -> Available plugins, search for and install Docker Pipeline.**
3. Create Admin User: Create your admin user account.
4. Set Jenkins URL: Go to **Manage Jenkins -> System.** In the Jenkins Location section, set the "Jenkins URL" to <http://jenkins-server:8080/>. Click Save.
   (This is crucial for webhook integrations to work correctly).
5. Create Jenkins API Token:
   - Click your username (top right) -> Configure.
   - Go to the "API Token" section and click "Add new Token".
   - Name it (e.g., gitea-webhook-token) and click Generate.
   - **Copy the generated token immediately and save it.** You will not be shown it again.

---

### Step 4c: Create and Configure Kubernetes Credentials

Before creating the Jenkins job, you must provide Jenkins with the credentials to access your K3s cluster.

1. **Apply the Service Account manifests** from the `sample-flask-app` repository to your cluster:

   ```bash
   kubectl apply -f /path/to/sample-flask-app/k8s/service-account.yaml
   kubectl apply -f /path/to/sample-flask-app/k8s/jenkins-token-secret.yaml
   ```
**_skip below to STEP 4CC to create then comeback and do 2nd and 3rd step below!_**

2. **Generate a custom `kubeconfig-jenkins.yaml` file.** This involves getting your cluster's dynamic port, gateway IP, CA certificate, and the Service Account Token.
3. **Upload this `kubeconfig-jenkins.yaml` file** to Jenkins as a "Secret file" credential with the ID `kubeconfig-sa`.

### Step 4cc: Creating custom Kubeconfig-jenkins.yaml file

#### Guide: How to Create the kubeconfig-jenkins.yaml File

- This file is the key that allows Jenkins to securely authenticate with your Kubernetes cluster using the dedicated jenkins-admin Service Account. You will construct this file by gathering four pieces of dynamic information from your running environment.

#### Prerequisites

- Your k3d cluster is running.

- You have already applied the service-account.yaml and jenkins-token-secret.yaml manifests to your cluster.

#### Step A1: Get the Cluster's Dynamic API Port

- Run this command in your WSL terminal to find the public port that your Kubernetes API server is listening on:

```bash
docker port k3d-devops-cluster-serverlb 6443
```

The output will be something like 0.0.0.0:34541. Note down the port number (e.g., 34541).

#### Step A2: Get the Docker Network Gateway IP

- This is the stable IP address of your host machine from the perspective of the Jenkins container.

```bash
docker network inspect big-project-2-cicd-pipeline_cicd-net --format '{{(index .IPAM.Config 0).Gateway}}'
```

The output will be an IP address. Note it down (e.g., 172.20.0.1).

#### Step A3: Get the Cluster's Certificate Authority (CA)

- This is the public certificate that your cluster uses to prove its identity.

```bash
# Get the full kubeconfig from k3d
k3d kubeconfig get devops-cluster
```

- From the YAML output, find the **certificate-authority-data field** under clusters:
  - Copy the entire long, single-line string of encoded text.
  - It will look like LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...

#### Step A4: Get the Jenkins Service Account Token

This is the "password" for the jenkins-admin user we created inside Kubernetes.

```bash
# This command gets the token from the secret we created
kubectl get secret jenkins-admin-token -o jsonpath='{.data.token}' | base64 --decode
```

This will output another very long string of characters starting with ey.... Copy this entire token.

#### Step A5: Assemble the kubeconfig-jenkins.yaml File

Now, create a new, empty file named kubeconfig-jenkins.yaml and paste the following template into it.

Template:

```yaml
apiVersion: v1
kind: Config
clusters:
  - name: k3d-devops-cluster
    cluster:
      server: https://<YOUR_GATEWAY_IP>:<YOUR_API_PORT>
      certificate-authority-data: <THE_BIG_CERTIFICATE_BLOCK>
users:
  - name: jenkins-admin
    user:
      token: <THE_SERVICE_ACCOUNT_TOKEN_YOU_COPIED>
contexts:
  - name: k3d-devops-cluster
    context:
      cluster: k3d-devops-cluster
      user: jenkins-admin
      namespace: default
current-context: k3d-devops-cluster
```

Fill in the placeholders using the four pieces of information you just collected.

---

You now have the complete and correct `kubeconfig-jenkins.yaml` file. The final step is to upload this file to the Jenkins credentials store as a "Secret file" with the ID `kubeconfig-sa`.

---

### Step 5: Configure the CI/CD Pipeline

1. Create the Jenkins Job:

   - In Jenkins, click "New Item".
   - Name: flask-app-pipeline, select "Pipeline", and click OK.
   - Scroll down to the "Pipeline" section and configure it as follows:
     - Definition: Pipeline script from SCM
     - SCM: Git
     - Repository URL: <http://gitea-server:3000/YOUR_GITEA_USERNAME/sample-flask-app.git> (replace GITEA Username with yours)
     - Branch Specifier: \*/main
   - Click Save.

2. Configure the Gitea Webhook:
   - In Gitea, go to your sample-flask-app repository -> Settings -> Webhooks.
   - Click "Add Webhook" -> "Gitea".
   - Target URL: Use the **following format or pattern below**, embedding your Jenkins username and the API token you just generated. This authenticates the request and bypasses CSRF protection (Not recommended for production.).

- **Pattern** - <http://YOUR_JENKINS_USER:YOUR_API_TOKEN@jenkins-server:8080/job/flask-app-pipeline/build/>

- **Example:** <http://admin:11a22b33c44d55e66f77g88h99i@jenkins-server:8080/job/flask-app-pipeline/build>

- Leave other settings as default and click "Add Webhook".

> **Important Note Again!** - Make sure u have Docker Plugin Installed in Jenkins. you must install the "Docker Pipeline" plugin to make it work!

**📦 How to Install Docker pipeline plugin (if not done):**

- Jenkins UI → Manage Jenkins → Plugins
- Go to Available
- Search for: Docker Pipeline
- Install and restart

> **Note:** This plugin is different from "Docker Commons Plugin" or "Docker plugin". You need Docker Pipeline, specifically.

---

### Step 6: Deploy the Monitoring Stack (Optional, but recommended)

- Use Helm to deploy Prometheus and Grafana into the cluster.

```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring -f helm-configs/prometheus-values.yaml

```

- Grafana accessible at `http://localhost:30900` (user/admin).
- _(Refer to helm-configs/prometheus-values.yaml for custom configuration.)_

- ***(important) Run this command to dynamically add the port mapping:***
```bash
k3d cluster edit devops-cluster --port-add 30900:30900@loadbalancer
```

---

### Step 7: Testing the Pipeline

You can now trigger the pipeline in two ways:

1. Manually: In Jenkins, go to the `flask-app-pipeline job` and click "Build Now".
2. Automatically: Make a code change in your local sample-flask-app, then git commit and git push it to Gitea. The pipeline should start within seconds.

After a successful run, you can view your deployed application at <http://localhost:8081>.

---

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

---


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
