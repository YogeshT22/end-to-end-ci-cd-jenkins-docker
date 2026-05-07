# Manual Setup (Advanced / Educational)

Manual setup instructioare provided below for educational purposes and to demonstrate the underlying infrastructure configuration process.

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
###
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
###
- **Note 1B** - Now run the code config given below to create a create a multi-node cluster.

```bash
k3d cluster create devops-cluster \
  --api-port 6550 \
  -p "8082:80@loadbalancer" \
  -p "30900:30900@loadbalancer" \
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
###
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
###
- From the YAML output, find the **certificate-authority-data field** under clusters:
  - Copy the entire long, single-line string of encoded text.
  - It will look like LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...

### Step 6.B: Get the Jenkins Service Account Token

This is the "password" for the jenkins-admin user we created inside Kubernetes.

```bash
# This command gets the token from the secret we created
kubectl get secret jenkins-admin-token -o jsonpath='{.data.token}' | base64 --decode
```
###
This will output another very long string of characters starting with ey.... Copy this entire token.

#### Step 6.C: Assemble the kubeconfig-jenkins.yaml File

Now, create a new, empty file named kubeconfig-jenkins.yaml and paste the following template into it.

> **⚠️ Critical:** The `server` URL **must** use `k3d-devops-cluster-serverlb:6443` (the k3d
> loadbalancer container hostname on the `cicd-net` Docker network). Do **not** use
> `host.docker.internal:6550` — that hostname is not in the API server's TLS certificate SANs
> and will cause an `x509: certificate is valid for ...` error inside the Jenkins container.

Template:

```yaml
apiVersion: v1
kind: Config
clusters:
  - name: k3d-devops-cluster
    cluster:
      server: https://k3d-devops-cluster-serverlb:6443
      certificate-authority-data: YOUR_BASE64_CA_HERE
users:
  - name: jenkins-admin
    user:
      token: YOUR_SERVICE_ACCOUNT_TOKEN_HERE
contexts:
  - name: jenkins-context
    context:
      cluster: k3d-devops-cluster
      user: jenkins-admin
      namespace: default
current-context: jenkins-context
```
###
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

###

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
- Install and restart Jenkins.

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
###
- Grafana accessible at `http://localhost:30900` (user/admin).
- _(Refer to helm-configs/prometheus-values.yaml for custom configuration.)_

---

### Step 9: Testing the Pipeline

You can now trigger the pipeline in two ways:

1. **Manually**: In Jenkins, go to the `flask-app-pipeline job` and click "Build Now".
2. **Automatically**: Make a code change in your local sample-flask-app, then git commit and git push it to Gitea. The pipeline should start within seconds.

After a successful run, you can view your deployed application at `<http://localhost:8082>`.

---

