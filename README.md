# DevSecOps CI/CD Pipeline

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Security](https://img.shields.io/badge/security-hardened-blue)
![License](https://img.shields.io/badge/license-MIT-green)

A comprehensive **DevSecOps** project demonstrating a secure Continuous Integration and Continuous Deployment (CI/CD) pipeline. This repository integrates security practices into every stage of the DevOps lifecycle ("Shifting Left").

## 📖 Table of Contents
- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Prerequisites](#-prerequisites)
- [Pipeline Stages](#-pipeline-stages)
- [Getting Started](#-getting-started)

---

## 🚀 Overview
This project automates the deployment of a web application while enforcing strict security checks. It moves beyond simple DevOps by embedding security tools (SAST, SCA, DAST, Container Scanning) directly into the pipeline.

**Key Features:**
- Automated Build & Release.
- Static Code Analysis (SAST) with SonarQube.
- Vulnerability scanning for dependencies (SCA) and Docker images.
- Kubernetes deployment with monitoring.

---

## 📐 Architecture
The pipeline follows a standard **Build -> Test -> Secure -> Deploy** flow:

`Code Push` -> `CI Server` -> `SAST Scan` -> `SCA Scan` -> `Build Docker Image` -> `Image Scan (Trivy)` -> `Deploy to K8s`

---

## 🛠 Tech Stack

| Category | Tool | Description |
| :--- | :--- | :--- |
| **VCS** | GitHub | Source Code Management |
| **CI/CD** | Jenkins / GitHub Actions | Automation Server |
| **Containerization** | Docker | Application Containerization |
| **Orchestration** | Kubernetes (K8s) | Container Orchestration |
| **IaC** | Terraform | Infrastructure provisioning |
| **Security** | SonarQube, Trivy, OWASP | SAST, SCA, and Image Scanning |
| **Monitoring** | Prometheus & Grafana | Metrics and Visualization |

---

## 📋 Prerequisites
Before running the pipeline, ensure you have:
1.  **Jenkins Server** with Docker and Java plugins.
2.  **SonarQube Server** running with an auth token.
3.  **DockerHub Account**.
4.  **Kubernetes Cluster** (EKS, AKS, or Minikube).

---

## 🔄 Pipeline Stages

1.  **Checkout**: Pull latest code from GitHub.
2.  **Static Analysis (SAST)**: SonarQube scan for bugs and vulnerabilities.
3.  **Dependency Scan (SCA)**: Check for vulnerable third-party libraries.
4.  **Build**: Create Docker image.
5.  **Image Scan**: Trivy scan for OS-level CVEs in the container.
6.  **Deploy**: Update Kubernetes manifests and apply changes.

---

## ⚡ Getting Started

### 1. Clone the Repo
```bash
git clone https://github.com/rushiwaman95/devsecops.git
cd devsecops
