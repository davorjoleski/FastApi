# 🚀 Project Title

---

## 🚀 Deployment Overview

This project uses:
- **Azure Kubernetes Service (AKS)**
- **Azure Container Registry (ACR)**
- **Azure Storage Account** for blob file upload
- **GitHub Actions** for CI/CD
- **Terraform** for provisioning all Azure resources

---

## 💻 LocalHost Run

- Local run on: `localhost:8000`
- Command:
  ```bash
  uvicorn main2.main2:app --reload
  ```
- Delete on `main [20]` for cutting the string of storage

---

## 🔧 Terraform Infrastructure (Inside `terraform/`)

Terraform provisions:
1. **Resource Group**
2. **ACR (Azure Container Registry)**
3. **AKS Cluster**
   - Connected with ACR using role `acrpull`
   - Outputs kubeconfig for GitHub Actions
4. **Storage Account**
5. **Blob Storage Container**
6. **Kubernetes Secret** (`azure-connection-secret`) for pulling images from ACR
7. **Outputs:**
   - kubeconfig
   - ACR URL
   - Storage connection string

---

## ⚙️ GitHub Actions Pipeline

- **Triggers** on push to master branch (or `main`, depending on use case).
- **Pipeline Steps**:
  - Builds Docker image for `main/` and `main2/`
  - Pushes to ACR
  - Runs `terraform init`, `plan`, `apply` from `terraform/`
  - Applies Kubernetes manifests using `kubectl` from Terraform outputs

---

## 🛠 Common Issues Faced & Solutions

| Problem                         | Description                              | Solution                                                                                                   |
|---------------------------------|------------------------------------------|------------------------------------------------------------------------------------------------------------|
| **ImagePullBackOff**            | AKS can't pull image from ACR            | Give AKS permission via `az ad sp create-for-rbac` and attach `--role acrpull`                             |
| **ImagePullBackOff (2)**        | AKS couldn’t pull images from ACR        | Fixed by creating Kubernetes secret (`azure-connection-secret`) with ACR credentials and mounting it in deployment (for Azure resource our case Storage Blob) `acr-secret` for AKS pod to pull image from ACR since pod doesn't have permission |
| **CrashLoopBackOff**            | App container crashes in loop            | Likely due to missing `.env` or syntax error in FastAPI app                                                |
| **CrashLoopBackOff (2)**        | App container restarted in loop          | Caused by missing `.env` or FastAPI config error; fixed by adding `.env` and checking container logs       |
| **Storage container exists**    | Terraform can't create container         | Use `terraform import` to bring it under management                                                        |
| **Service principal issues**    | `az ad sp create-for-rbac` returns nothing | Use full `--sdk-auth` format and assign role properly                                                     |
| **Public IP not reachable**     | AKS ingress IP not working               | Use `kubectl get svc` to confirm external IP is assigned                                                   |
| **Not authorized on ACR**       | GitHub Actions can't push image          | Ensure secrets like `AZURE_CREDENTIALS` and `ACR_NAME` are properly configured                             |

---

## 📈 Testing Replicas, HPA, Manual Scaling, Auto Scaling and Virtual Scaling

- **HPA (Horizontal Pod Autoscaler)**  
  - Added in Terraform v2  
  - Auto chooses scaling depending on CPU (UTS)  
  - Configured with:
    - Minimum replicas
    - Maximum replicas
    - Required CPU in deployment YAML file (resources section)

---

## 🔐 Secrets Required in GitHub

Set in **repository settings → Secrets and variables → Actions**:

- `AZURE_CREDENTIALS`: Output from `az ad sp create-for-rbac --sdk-auth`
- `SUBSCRIPTION_ID`
- `RESOURCE_GROUP`
- `ACR_NAME`
- `STORAGE_ACCOUNT_NAME`

---

## 📄 Deployment Steps

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd <repo>
   ```

2. **Authenticate with Azure**
   ```bash
   az login
   ```

3. **Run Terraform**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

4. **Push code to branch**
   - Push to `main` or `master`
   - GitHub Actions triggers pipeline

---

✅ Final Result:  
Application is deployed to **Azure AKS**, using **Terraform** for infrastructure provisioning, **ACR** for image hosting, **Blob Storage** for file storage, and **GitHub Actions** for automated CI/CD.
