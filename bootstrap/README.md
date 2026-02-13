# Bootstrap

This folder contains the one-time initialization script required before Terraform or GitHub Actions can manage Azure infrastructure.

It must be executed **before** running Terraform.

After bootstrap, all infrastructure must be managed via Terraform only.


---

## Files

- `bootstrap.sh` — bootstrap script (run once)

---

## ⚠️ Before Running the Script (Manual Changes Required)

Open `bootstrap/bootstrap.sh` and update the configuration variables at the top of the file.

You must review and set the following variables:

### Azure Configuration

- `SUBSCRIPTION_ID`  
  Your Azure subscription ID (GUID).

- `TENANT_ID`  
  Your Microsoft Entra (Azure AD) tenant ID.

You can retrieve both using:

```bash
az login
az account show
```

- `LOCATION`  
  Azure region where resources will be created (e.g. `westeurope`).

---

### GitHub Configuration (OIDC Federation)

These values must match your GitHub repository exactly:

- `GITHUB_OWNER`  
  Your GitHub username or organization name.

- `GITHUB_REPO`  
  Name of this repository (e.g. `PinMyDay.Infra`).

- `ENV_DEV`  
  Name of the GitHub Environment for development (usually `dev`).

- `ENV_PROD`  
  Name of the GitHub Environment for production (usually `prod`).

You must create these environments in GitHub:

Settings → Environments

---

### Terraform Remote State Configuration

Terraform requires remote state storage in Azure Blob Storage.

- `TFSTATE_RG`  
  Resource Group for Terraform state storage.

- `TFSTATE_SA_PREFIX`  
  Prefix for the Storage Account name.  
  Must be:
    - lowercase
    - alphanumeric
    - globally unique
    - maximum 24 characters

- `TFSTATE_CONTAINER`  
  Blob container name (usually `tfstate`).

---

### Identity Configuration

- `APP_NAME`  
  Name of the Entra App Registration created for GitHub Actions (e.g. `pmd-terraform-gha`).

This identity will:
- Have a Service Principal created
- Be assigned Contributor role on the subscription
- Contain federated credentials for GitHub OIDC authentication

---

## Prerequisites

- Azure CLI installed
  - https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest
  - Multifactor authentication setup is required from Azure Portal
- You can authenticate to Azure (the script will prompt you via az login if needed)
- Sufficient Azure permissions (Owner recommended)

---

## Run Bootstrap

From repository root:

```bash
chmod +x bootstrap/bootstrap.sh
./bootstrap/bootstrap.sh
```

The script will:

- Create Azure Blob Storage for Terraform state
- Create App Registration and Service Principal
- Assign Contributor role
- Configure GitHub OIDC federation
- Output required values for GitHub Actions

---

## After Running

1. In GitHub → Settings → Environments  
   Create:
    - `dev`
    - `prod` (recommended: require approval)

2. In GitHub → Settings → Secrets and variables → Actions → Variables  
   Add:
    - `AZURE_CLIENT_ID`
    - `AZURE_TENANT_ID`
    - `AZURE_SUBSCRIPTION_ID`

3. Create Terraform backend configuration locally (do NOT commit):

`infra/envs/dev/backend.tf`

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<TFSTATE_RESOURCE_GROUP>"
    storage_account_name = "<TFSTATE_STORAGE_ACCOUNT>"
    container_name       = "<TFSTATE_CONTAINER>"
    key                  = "pmd-dev.tfstate"
  }
}
```

For production use:

```hcl
key = "pmd-prod.tfstate"
```

