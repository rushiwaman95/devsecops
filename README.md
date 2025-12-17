A comprehensive DevSecOps project demonstrating a secure Continuous Integration and Continuous Deployment (CI/CD) pipeline. This repository integrates security practices into every stage of the DevOps lifecycle ("Shifting Left"), ensuring that security vulnerabilities are detected and remediated early in the development process.[1][2]
📖 Table of Contents
Overview
Architecture & Workflow
Tech Stack
Prerequisites
Directory Structure
Pipeline Stages
Getting Started
Screenshots
Future Enhancements
🚀 Overview
This project automates the deployment of a web application while enforcing strict security checks. It moves beyond simple DevOps by embedding security tools (SAST, SCA, DAST, Container Scanning) directly into the pipeline.
Key Features:
Automated Build & Release.[3]
Static Code Analysis for quality and security.
Vulnerability scanning for dependencies and container images.
Infrastructure as Code (IaC) provisioning.
Kubernetes deployment with monitoring.[2][4]
d Architecture & Workflow
The pipeline follows a standard Build -> Test -> Secure -> Deploy flow:
code
Mermaid
graph LR
    A[Code Push] --> B[CI Server]
    B --> C{SAST Scan}
    C -- Pass --> D{SCA Scan}
    D -- Pass --> E[Build Docker Image]
    E --> F{Image Scan}
    F -- Pass --> G[Push to Registry]
    G --> H[Update K8s Manifests]
    H --> I[Deploy to K8s]
    I --> J[DAST Scan / Monitor]
🛠 Tech Stack
Category	Tool	Description
VCS	GitHub	Source Code Management
CI/CD	Jenkins / GitHub Actions	Automation Server
Containerization	Docker	Application Containerization
Orchestration	Kubernetes (K8s)	Container Orchestration
IaC	Terraform	Infrastructure provisioning
Code Quality	SonarQube	Static code analysis & Quality Gates
SAST	SonarQube / Trivy	Static Application Security Testing
SCA	OWASP Dependency Check	Software Composition Analysis
Image Security	Trivy / Docker Scout	Container Image Scanning
Monitoring	Prometheus & Grafana	Metrics and Visualization
📋 Prerequisites
Before running the pipeline, ensure you have the following set up:
AWS/Azure/GCP Account: For cloud infrastructure.[5][6]
Jenkins Server (or GitHub Actions runner): With Docker and Java installed.
SonarQube Server: Up and running with a generated authentication token.
DockerHub Account: To store container images.
Kubernetes Cluster: (EKS, AKS, GKE, or Minikube) accessible via kubectl.
📂 Directory Structure
code
Bash
├── app/                  # Application Source Code
│   ├── src/              # Source files
│   ├── tests/            # Unit tests
│   └── Dockerfile        # Container definition
├── k8s/                  # Kubernetes Manifests
│   ├── deployment.yaml   # Deployment config
│   └── service.yaml      # Service/Ingress config
├── terraform/            # Infrastructure as Code
│   ├── main.tf           # Main provider config
│   └── variables.tf      # Variable definitions
├── Jenkinsfile           # CI/CD Pipeline Script (Groovy)
├── README.md             # Project Documentation
└── requirements.txt      # Dependencies (if Python/Node)
🔄 Pipeline Stages[4]
1. Checkout & Init
Pull the latest code from the GitHub repository and initialize environment variables.
2. Static Code Analysis (SAST)
Tool: SonarQube
Action: Scans source code for bugs, code smells, and security vulnerabilities.
Gate: Pipeline fails if "Quality Gate" is not met (e.g., Critical bugs > 0).
3. File System Scan & SCA
Tool: Trivy / OWASP Dependency Check
Action: Scans the file system for secrets (API keys) and checks third-party libraries (SCA) for known CVEs.
4. Build & Tag
Build the Docker image from the Dockerfile and tag it with the build ID/commit hash.
5. Container Image Scanning
Tool: Trivy
Action: Scans the built Docker image for OS-level vulnerabilities (e.g., High/Critical CVEs) before pushing.
6. Push to Registry
Push the secure image to DockerHub or ECR.
7. Deployment
Deploy the application to the Kubernetes cluster using the updated image.
⚡ Getting Started
Step 1: Clone the Repo
code
Bash
git clone https://github.com/rushiwaman95/devsecops.git
cd devsecops
Step 2: Configure Secrets
If using Jenkins, add the following credentials in Manage Jenkins -> Credentials:
sonar-token: SonarQube authentication token.
docker-creds: DockerHub username and password.
k8s-kubeconfig: Kubernetes config file (Secret file).
git-creds: GitHub Personal Access Token.
Step 3: Infrastructure Setup (Optional)
If you need to provision infrastructure first:
code
Bash
cd terraform
terraform init
terraform apply --auto-approve
Step 4: Run the Pipeline
Go to your Jenkins Dashboard.
Create a new Pipeline job.
Under "Pipeline Definition", select Pipeline script from SCM.
Enter this repo URL and specify the branch (e.g., main or master).
Click Build Now.
🔮 Future Enhancements
DAST Integration: Add OWASP ZAP to scan the running application after deployment.
Slack Notifications: Integrate Slack Webhooks for build success/failure alerts.
GitOps: Implement ArgoCD for continuous deployment sync.
🤝 Contribution
Contributions are welcome![5] Please fork the repository and create a Pull Request for any improvements.
Fork the Project[3]
Create your Feature Branch (git checkout -b feature/NewFeature)
Commit your Changes (git commit -m 'Add some NewFeature')
Push to the Branch (git push origin feature/NewFeature)
Open a Pull Request[7]
Author: rushiwaman95
Sources
help
codefresh.io
hackernoon.com
youtube.com
infosecinstitute.com
github.com
youtube.com
youtube.com
