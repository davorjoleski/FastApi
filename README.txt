
---

## 🚀 Deployment Overview

This project uses:

- Azure Kubernetes Service (AKS)
- Azure Container Registry (ACR)
- Azure Storage Account for blob file upload
- GitHub Actions for CI/CD
- Terraform for provisioning all Azure resources

---

## 🔧 Terraform Infrastructure (Inside `terraform/`)

1. **Resource Group**
2. **ACR (Azure Container Registry)**
3. **AKS Cluster**
4. **Storage Account**
5. **Storage Container**
6. **Outputs for kubeconfig and ACR URL**

---

## ⚙️ GitHub Actions Pipeline

- Triggers on push to `master` branch.
- Builds Docker image for `main/` and `main2/`.
- Pushes to ACR.
- Runs `terraform init`, `plan`, `apply` from `terraform_test/`.
- Applies Kubernetes manifests using `kubectl` from Terraform outputs.

---

## 🛠 Common Issues Faced & Solutions

| Problem | Description | Solution |
|--------|-------------|----------|
| `ImagePullBackOff` | AKS can't pull image from ACR | Give AKS permission via `az ad sp create-for-rbac` and attach `--role acrpull` |
| `CrashLoopBackOff` | App container crashes in loop | Likely due to missing `.env` or syntax error in FastAPI app |
| Storage container already exists | Terraform can't create container | Use `terraform import` to bring it under management |
| Service principal creation issues | `az ad sp create-for-rbac` returns nothing | Use full `--sdk-auth` format and assign role properly |
| Public IP not reachable | AKS ingress IP not working | Use `kubectl get svc` to confirm external IP is assigned |
| Not authorized on ACR | GitHub Actions can't push image | Ensure secrets like `AZURE_CREDENTIALS` and `ACR_NAME` are properly configured |

---

## 🔐 Secrets Required in GitHub

Set in repository settings > Secrets and variables > Actions:

- `AZURE_CREDENTIALS`: Output from `az ad sp create-for-rbac --sdk-auth`
- `SUBSCRIPTION_ID`
- `RESOURCE_GROUP`
- `ACR_NAME`
- `STORAGE_ACCOUNT_NAME`

---

## 📄 Deployment Steps

1. Clone the repository
2. Authenticate with Azure:
   ```bash
   az login
