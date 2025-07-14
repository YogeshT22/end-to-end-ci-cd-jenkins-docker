# Project: End-to-End CI/CD Pipeline Platform

This repository contains the infrastructure-as-code for a complete, local CI/CD ecosystem built with Docker. It uses Docker Compose to orchestrate **Gitea**, **Jenkins**, and a private **Docker Registry**, creating a fully automated software delivery pipeline.

This platform is designed to continuously integrate, build, and deploy a sample application. The entire system demonstrates a real-world DevOps workflow, including automated triggers, artifact management, and solutions to common configuration and networking challenges.

**Companion Application Repository:** [https://github.com/YogeshT22/sample-flask-app](https://github.com/YogeshT22/sample-flask-app)

---

## Core Concepts & Skills Demonstrated

*   **CI/CD Pipeline Design:** Implemented a full, end-to-end pipeline covering all stages: `Git Push` -> `Webhook Trigger` -> `Code Checkout` -> `Docker Build` -> `Push to Registry` -> `Deploy`.
*   **Infrastructure as Code (IaC):** Defined the entire multi-service platform in a single `docker-compose.yml` file, making the environment completely reproducible and version-controlled.
*   **Pipeline-as-Code:** Wrote a declarative `Jenkinsfile` to define the entire CI/CD process, ensuring the pipeline logic is version-controlled with the application code.
*   **Custom Build Environments:** Built a custom Jenkins image using a `Dockerfile` to bake in necessary dependencies (Git, Docker CLI), creating a stable and predictable build environment.
*   **Internal Networking & Service Discovery:** Configured a shared Docker network (`cicd-net`) to allow services to communicate reliably using their service names.
*   **Artifact Management:** Deployed and used a private Docker Registry for storing and versioning the container images (artifacts) built by the pipeline.
*   **Complex Debugging & Problem Solving:** Solved container tool-chain issues (`docker: not found`), resolved webhook security blocks (`403 Forbidden`, `Host Not Allowed`), and fixed cross-platform networking issues.

---

## Architecture Diagram

```mermaid
graph TD
    subgraph "Developer's Machine (WSL)"
        Dev(Developer) -- "1. git push" --> Gitea[Gitea Server:3000];
    end

    subgraph "Docker CI/CD Platform (Managed by Docker Compose)"
        Gitea -- "2. Webhook Trigger" --> Jenkins[Jenkins Server:8080];
        Jenkins -- "3. Checkout Code" --> Gitea;
        Jenkins -- "4. Build Image" --> DockerSocket[(Host's Docker Socket)];
        Jenkins -- "5. Push Image" --> Registry[Local Registry:5000];
        Jenkins -- "6. Deploy Container" --> DockerSocket;
    end

    subgraph "Deployed Application"
        DockerSocket -- "7. Runs a new container" --> DeployedApp([Flask App Container]);
    end

    subgraph "End User"
        User(End User) -- "8. Accesses App @ localhost:8081" --> DeployedApp;
    end
```
---

## Getting Started: A Step-by-Step Guide

This guide will walk you through setting up the entire platform from scratch.

#### Part 1: Prerequisites

* **WSL2**: Ensure you have WSL2 installed on your Windows machine with a Linux distribution (e.g., Ubuntu).
* **Docker Desktop**: Install Docker Desktop and enable the WSL2 integration in Settings -> Resources -> WSL Integration.
* **Clone Both Repositories**: Clone this repository (end-to-end-ci-cd-jenkins-docker) and its companion (sample-flask-app) into your WSL filesystem.

```bash
# Example:
git clone https://github.com/YogeshT22/end-to-end-ci-cd-jenkins-docker.git
git clone https://github.com/YogeshT22/sample-flask-app.git
```
#### Part 2: One-Time Host Configuration

1. Your Docker daemon must be configured to trust the local registry. This only needs to be done once.

``Open Docker Desktop -> Settings -> Docker Engine.``

2. Add the insecure-registries key to the JSON configuration:
```bash
"insecure-registries": [
  "localhost:5000"
]
```
3. Click "Apply & Restart".

#### Part 3: Launch the Infrastructure

Navigate into this project's directory (end-to-end-ci-cd-jenkins-docker) and launch all services.
```bash
# This builds the custom Jenkins image and starts all containers
docker-compose up --build -d
```

Wait 2-3 minutes for all services to initialize before proceeding.

#### Part 4: Gitea First-Time Setup

1. Open your browser to http://localhost:3000.
2. On the initial configuration page, it is critical to set the following:
    - Database Type: SQLite3 (default is fine).
    - Server Domain: gitea-server
    - Gitea Base URL: http://gitea-server:3000/

(This ensures Jenkins can find Gitea using its service name on the Docker network).

3. Expand "Administrator Account Settings" and create your admin user.
4. Click "Install Gitea" and log in.
5. Create a new public repository named sample-flask-app.
6. Follow the instructions on the Gitea page to push your local sample-flask-app code to this new repository.

#### Part 5: Jenkins First-Time Setup

1. Unlock Jenkins: Get the initial admin password from the logs:
```bash
docker logs jenkins-server
```
Go to http://localhost:8080, paste the password, and continue.

2. Install Plugins: Select "Install suggested plugins". After the initial install, go to Manage Jenkins -> Plugins -> Available plugins, search for and install Docker Pipeline.
3. Create Admin User: Create your admin user account.
4. Set Jenkins URL: Go to Manage Jenkins -> System. In the Jenkins Location section, set the "Jenkins URL" to http://jenkins-server:8080/. Click Save.
(This is crucial for webhook integrations to work correctly).
5. Create Jenkins API Token:
    - Click your username (top right) -> Configure.
    - Go to the "API Token" section and click "Add new Token".
    - Name it (e.g., gitea-webhook-token) and click Generate.
    - **Copy the generated token immediately and save it.** You will not be shown it again.

#### Part 6: Configure the CI/CD Pipeline

1. Create the Jenkins Job:
    - In Jenkins, click "New Item".
    -  Name: flask-app-pipeline, select "Pipeline", and click OK.
    - Scroll down to the "Pipeline" section and configure it as follows:
        - Definition: Pipeline script from SCM
        - SCM: Git
        - Repository URL: http://gitea-server:3000/YOUR_GITEA_USERNAME/sample-flask-app.git
        - Branch Specifier: */main
    - Click Save.

2. Configure the Gitea Webhook:
    - In Gitea, go to your sample-flask-app repository -> Settings -> Webhooks.
    - Click "Add Webhook" -> "Gitea".
    - Target URL: Use the following format, embedding your Jenkins username and the API token you just generated. This authenticates the request and bypasses CSRF protection.
    http://YOUR_JENKINS_USER:YOUR_API_TOKEN@jenkins-server:8080/job/flask-app-pipeline/build
        - _Example: http://admin:11a22b33c44d55e66f77g88h99i@jenkins-server:8080/job/flask-app-pipeline/build_
    
    - Leave other settings as default and click "Add Webhook".

#### Part 7: Testing the Pipeline
You can now trigger the pipeline in two ways:
1. Manually: In Jenkins, go to the flask-app-pipeline job and click "Build Now".
2. Automatically: Make a code change in your local sample-flask-app, then git commit and git push it to Gitea. The pipeline should start within seconds.

After a successful run, you can view your deployed application at http://localhost:8081.

---

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.