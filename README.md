# PinMyDay Infrastructure

Infrastructure-as-Code (Terraform) for deploying the PinMyDay platform to Microsoft Azure.

This repository defines:

- Azure landing-zone–style structure
- Environment separation (dev / prod)
- Terraform remote state configuration
- CI/CD integration via GitHub Actions (OIDC, no stored secrets)
- Cost-optimized ("free") and full architecture modes

---

# 🚀 Getting Started

Before running Terraform or GitHub Actions pipelines, an initial bootstrap step is required.

## Initial Setup (Required Once Per Subscription)

You must execute the bootstrap process described in:

```
bootstrap/README.md
```

---

# 📁 Repository Structure

```
bootstrap/        # One-time initialization (state + identity)
infra/
  modules/        # Reusable Terraform modules
  envs/
    dev/          # Development environment
    prod/         # Production environment
```

---

# 🏗 Deployment Modes

This infrastructure describes two deployment profiles:

- `free`  — Cost-optimized demo architecture
- `full`  — Enterprise-grade reference architecture

The same module structure is preserved; resource implementation depends on budget mode.

---

# 🔐 Security Model

- No long-lived secrets stored
- GitHub Actions authenticates using OIDC federation
- Azure RBAC used for access control
- Terraform state stored remotely in Azure Blob Storage

---

# 📌 Notes

- Bootstrap must be executed once per Azure subscription.
- After bootstrap, all infrastructure changes must be managed via Terraform only.
- `backend.tf` files are not committed to version control.