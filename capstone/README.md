# Capstone: Deploy a 3-tier app on Azure with Terraform

Every student builds the **same complete infrastructure** in one shared Azure account:
one AKS cluster (1 worker node), a private container registry, Key Vault, a WAF in
front, and their own subdomain - then deploys a **Frontend + Backend + Database** app on it.

```
Internet -> app.student03.lab.collabgigs.com
         -> Azure DNS -> Application Gateway (WAF) -> internal Load Balancer
         -> AKS: [ frontend ] -> [ backend ] -> [ PostgreSQL on an Azure Disk ]
                                    |
                                    +-> Key Vault (read with Entra ID, no password)
```

## 30-second start (student)

```bash
./scripts/login.sh          # or: ./scripts/login.sh sp   (see docs/INSTALL.md)
./scripts/deploy.sh student03     # your id from the instructor - about 15 min
./scripts/validate.sh student03   # proves it all works
# open the URL it prints
./scripts/destroy.sh student03    # when finished - stops the billing
```

Everything you can change lives in **one file**: `config/master-values.yaml`.
Every secret lives in **one other file**: `config/secrets.env` (git-ignored; copy `config/secrets.env.example`, and the instructor sends you the real one privately).

## What is in this repo

| Folder | What it is |
|---|---|
| `config/master-values.yaml` | **The one master file.** Region, VM size, domain, and one row per student. |
| `infra/` | **Root module.** Reads the master file and calls every child module. |
| `modules/` | **Child modules**, one per Azure service (table below). |
| `app/` | The application: `frontend` (nginx + HTML) and `backend` (Python/Flask). |
| `scripts/` | `preflight`, `deploy`, `validate`, `destroy`, `build-images`. |
| `bootstrap/` | Instructor, run once: creates storage for Terraform state. |
| `docs/` | Install, architecture, lab guide, instructor guide, troubleshooting. |
| `presentation/` | Slide deck to introduce the lab. |

## Child modules

| Module | Azure service | What it creates |
|---|---|---|
| `network` | Virtual Network | VNet, AKS subnet, Application Gateway subnet, NSG |
| `identity` | Microsoft Entra ID | Managed identity for the cluster + network role |
| `acr` | Container Registry | Private registry for the 3 images |
| `keyvault` | Key Vault | Vault (RBAC), DB password + banner secrets |
| `aks` | Kubernetes Service | Cluster, 1 node, Entra login, OIDC, ACR pull role |
| `workload-identity` | Microsoft Entra ID | Pod identity that may read the vault |
| `storage` | Storage Account | Account + `db-backups` container |
| `appgw` | Application Gateway + WAF | Public IP, WAF policy (OWASP 3.2), gateway |
| `dns` | Azure DNS (+ Cloudflare) | Student zone, `app` A record, NS delegation |
| `k8s-app` | Kubernetes + Azure Disk + Load Balancer | Namespace, PostgreSQL StatefulSet (Azure Disk), backend, frontend, internal Load Balancer |

The modules are small, plain `azurerm` code written to be read and learned from. They
are not wrappers around the Azure Verified Modules; each can be swapped for the matching
AVM module later (see `docs/INSTRUCTOR.md`).

## Read next
1. `docs/INSTALL.md` - install the tools
2. `docs/LAB-GUIDE.md` - the step-by-step lab
3. `docs/ARCHITECTURE.md` - how it fits together
4. `docs/INSTRUCTOR.md` - setup, quotas, cost, cleanup
5. `docs/TROUBLESHOOTING.md` - when something goes wrong
