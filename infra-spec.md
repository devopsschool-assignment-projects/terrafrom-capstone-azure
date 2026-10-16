# Infra Spec (current state)

Last updated: 2026-10-16

## Goal
15 students, each creating 1 AKS cluster with 2 nodes, in a single region.

## Region / VM size
- Region: **westus3**
- Node VM size: **Standard_D2s_v6** (2 vCPU), available in westus3 with no restrictions.

## Sizing
- 15 students x 2 nodes x 2 vCPU = 60 vCPUs
- Plus ~30 for AKS upgrade surge (1 extra node per cluster) and buffer -> target 100 vCPUs.

## Quotas in westus3
| Quota | Original | Target | Current status |
|---|---|---|---|
| Total Regional vCPUs (`cores`) | 30 | 100 | **190 at 2026-10-16 recheck** |
| StandardDSv3Family | 10 | - | Deprecated, cannot be raised |
| standardDSv5Family | 0 | 100 | Request failed ("Request failed.") |
| StandardDsv6Family | 10 | 100 | **100, approved** |
| StandardDDSv6Family / StandardDLDSv6Family | - | - | Auto-raised by Azure to 20 each (not requested) |

Other regions (eastus, centralindia, japaneast, westeurope): 10 regional vCPUs each, unchanged.

## Student command
```
az aks create -g <rg> -n <name> -l westus3 --node-count 2 --node-vm-size Standard_D2s_v6
```

## Fallbacks if Dsv6 is rejected
1. Open a support ticket for the Dsv6 family quota.
2. Split students across regions (westus3 + eastus) with smaller increases each.

## Useful commands
```
az vm list-usage -l westus3 -o table --query "[?name.value=='cores' || name.value=='StandardDsv6Family'].{n:name.value,used:currentValue,limit:limit}"
az quota request status list --scope /subscriptions/092c8f39-7113-46c4-8cce-d26a6afd9f67/providers/Microsoft.Compute/locations/westus3
az quota update --resource-name StandardDsv6Family --scope <scope above> --limit-object value=100 --resource-type dedicated
```

## Existing resource groups (pre-existing, not created by this work)
rg-devops-demo, rajesh-motoshare-workspace-var (japaneast); tg-hcp-01, rg-dip, rg-tfmod-01-lb, ex-rg-swathi, ex-rg-sree, rg-demo12, rg-sakshi-d2-ass1-20261013, NetworkWatcherRG, example-sree-workspace (westus3); Khuma-tfcloud, rg-tfmod-sakshi-01 (eastus); rg-terraform-lab-centralindia-rt-test, rg-ys-d4 (centralindia); rg-terraform-dev-gt (westeurope). No AKS clusters existed at start.

## Domain: collabgigs.com
- Available as of 2026-10-16, NOT purchased. Azure App Service Domains is not allowed for this subscription (error 59743).
- Empty resource group `rg-domains` (westus3) exists for it.
- Plan: buy at another registrar, then optionally create an Azure DNS zone and point nameservers to it.

## DNS design (2026-10-16)
- collabgigs.com: registrar + DNS at Cloudflare (zone active). Cloudflare API token (Zone > DNS > Edit, this zone only) validated; kept out of files, supply via env var CLOUDFLARE_API_TOKEN when needed.
- `lab.collabgigs.com` Azure zone is created by the student lab code, NOT pre-created (earlier one deleted).
- Planned: one child zone per student, DNS Zone Contributor scoped per student. Students never need Cloudflare access.

## Access (checked 2026-10-16, read-only)
- Entra users: Rajesh Kumar (Owner + User Access Administrator), shared student user `lab@app9devopsschool.onmicrosoft.com` (Contributor on subscription).
- Service principal `terraform` (appId ab00fa9f-c1ea-46ac-8abc-3b577a7b6e79): Contributor on subscription. Other app registrations: tf-gt, terraform-deployer.
- All 15 students share one identity (`lab`), so no per-student RBAC isolation. Contributor cannot assign roles.

## Capstone status (2026-10-16)
- Code in capstone/, tested end to end with student01 (all validate.sh checks passed), then destroyed.
- lab login: Contributor + Role Based Access Control Administrator (subscription). Remove after the course.
- Quotas westus3: Dsv6 100, regional vCPUs 190, public IPs 40.
