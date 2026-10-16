# Changes Log

Append new entries at the bottom. Format: date - what - result.

## 2026-10-16
- Verified Azure CLI access (read-only): signed in as app9@devopsschool.com, subscription Pay-As-You-Go - new.
- Read-only audit: regional vCPU limits were 30 (westus3) and 10 (eastus, centralindia, japaneast, westeurope); no usage, no AKS clusters.
- Requested `cores` (Total Regional vCPUs) in westus3: 30 -> 100. **Succeeded.**
- Requested `standardDSv3Family` -> 100. **Rejected** (DeprecatedQuotaType; Azure recommends v5/v6/v7 families).
- Requested `standardDSv5Family` -> 100. **Failed** ("Request failed.").
- Requested `StandardDsv6Family` -> 100 (request id bfbcd3e6...). **In progress**; limit still 10 at last check.
- Azure auto-raised StandardDDSv6Family and StandardDLDSv6Family to 20 each (not requested by us).
- Created `CLAUDE.md`, `infra-spec.md`, `changes.md` in /Users/rajesh/training for migration to a new laptop.

## Next
- Recheck Dsv6 limit; if still 10 or failed, open support ticket or split regions (see infra-spec.md).

## 2026-10-16 (domain)
- Checked collabgigs.com availability (read-only): available, no WHOIS record.
- Registered resource provider Microsoft.DomainRegistration on the subscription (free).
- Domain NOT yet purchased: waiting for full contact address (city, state, postal code, country).
- Created resource group `rg-domains` (westus3), empty, intended for the domain.
- Attempted to buy collabgigs.com via App Service Domains ($11.99 USD, privacy on, auto-renew on). **Rejected by Azure**: "The subscription is not eligible to create an App Service Domain" (ExtendedCode 59743). Nothing was purchased or charged.
- Note: `az appservice domain create` also fails locally ("Unable to get IP address", hostname does not resolve on this Mac), so the REST API was called directly.
- Contact details used (address shortened to fit 41-char limit): Rajesh Kumar, contact@cotocus.com, +91.7482845286, Flat 103 Ground Fl, Highway View Apt / Plot 1370 Thana 34 Ward 29 Telidih Tand, Chas, Bokaro, Jharkhand 827013, IN.
- Next: buy collabgigs.com at another registrar, then optionally host DNS in Azure. Decide whether to delete empty `rg-domains`.
- Tried to open a support ticket via CLI (App Service Domains / Purchasing Domain, then Subscription management). **Failed**: InvalidSupportPlan, plan is Free; the support API needs a paid plan. No ticket exists. Ticket must be raised in the Azure portal (Help + support) instead.
- Findings: billing account "DevOpsSchool" is a Microsoft Customer Agreement; subscription offer PayAsYouGo_2014-09-01; spending limit off.
- Also useful: Subscription management has "Compute-VM (cores-vCPUs) subscription limit increases" for the Dsv6 quota if it stays at 10.

## 2026-10-16 (DNS)
- User bought collabgigs.com at Cloudflare (registrar + DNS for apex stays at Cloudflare).
- Registered provider Microsoft.Network.
- Created resource group `rg-dns-lab` (westus3) and Azure DNS zone `lab.collabgigs.com`.
- Azure nameservers: ns1-05.azure-dns.com, ns2-05.azure-dns.net, ns3-05.azure-dns.org, ns4-05.azure-dns.info
- Pending (user): add 4 NS records named `lab` in Cloudflare pointing at those nameservers (proxy off).
- Next: create per-student child zones (student01..15.lab.collabgigs.com) + delegate NS in lab zone, assign DNS Zone Contributor per student. Need student identity method.

## 2026-10-16 (correction)
- User said the lab zone must be created by the student lab code, not by us. Deleted `lab.collabgigs.com` zone and resource group `rg-dns-lab` (both contained only default records). NS values listed above are therefore obsolete; new zone will get different nameservers.
- Cloudflare API token validated (active, sees only collabgigs.com zone, status active). Token NOT stored in any file. It was pasted in chat, so it should be rolled/deleted after the lab setup.
- `rg-domains` (empty, westus3) still exists from the failed domain purchase.
- Read-only check of student access: single shared user `lab@...` (Contributor, subscription scope), SP `terraform` (Contributor). No per-student accounts.

## 2026-10-16 (quota recheck)
- StandardDsv6Family request bfbcd3e6 **Succeeded**: limit now 100 in westus3.
- `cores` (Total Regional vCPUs) now shows 190 (we requested 100; Azure raised it further, likely auto-adjusted after the family increases). Usage 0.

## 2026-10-16 (capstone prep)
- Requested Network quota `IPv4StandardSkuPublicIpAddresses` in westus3: 20 -> 40 (user approved). **Succeeded**; `PublicIPAddresses` also shows 40. Reason: 12 students x 2 public IPs (App Gateway + AKS outbound) = 24 > 20.
- Created project skeleton /Users/rajesh/training/capstone (Terraform lab for 12 students).
- Cloudflare zone id for collabgigs.com: 907a8a93f3fad1dea81000805448240d (not secret).
- Wrote capstone codebase (modules: network, identity, acr, keyvault, aks, storage, appgw, dns, workload-identity, k8s-app; root in infra/; bootstrap/; scripts/; app/). `terraform validate` passes.
- Applied capstone/bootstrap: created RG `rg-cap-tfstate` + storage account `stcaptf6o328` + container `tfstate` (holds all student state files). Wrote capstone/config/backend.hcl.
- Next: plan + deploy ONE test student (student01) with Cloudflare delegation, run scripts/validate.sh, then destroy test resources and remove Cloudflare NS test records.
- Wrote docs (README, INSTALL, ARCHITECTURE, LAB-GUIDE, INSTRUCTOR, TROUBLESHOOTING) and presentation/capstone.pptx (12 slides; passes structural validation; NOT visually rendered because LibreOffice is not installed).
- TEST DEPLOY: applying reviewed plan for student01 (43 resources, incl. 4 Cloudflare NS records `student01.lab.collabgigs.com`). An earlier blind apply was blocked, so a saved plan was reviewed first. Cloudflare token passed via env var only, not stored.
- Cleanup TODO after validation: ./scripts/destroy.sh student01 (removes Azure resources + Cloudflare NS records); delete infra/student01.tfplan (contains sensitive values).

## 2026-10-16 (test result)
- student01 TEST DEPLOY: 43 resources created. validate.sh: ALL CHECKS PASSED (1 node Ready; postgres/backend/frontend Ready; PVC Bound; DNS resolves; GET / 200; /api/health 200; banner from Key Vault via workload identity; POST 201 + read-back; WAF 403 on XSS). Pod deletion test: DB data survived.
- Fixed bug in scripts/validate.sh (empty array under `set -u` on macOS bash 3.2).
- Destroying student01 test environment (azure resources + Cloudflare NS records).
- student01 test destroyed: 43 resources removed, rg-cap-student01 gone, Key Vault purged, no Cloudflare NS records left. Deleted infra/student01.tfplan.
- Granted "Role Based Access Control Administrator" to lab@app9devopsschool.onmicrosoft.com at subscription scope (user approved). lab now has Contributor + RBAC Administrator. Remove after the course (it lets that login grant itself roles).
- Cloudflare token can now come from config/master-values.yaml (`global.cloudflare_api_token`, currently commented/empty) or env TF_VAR_cloudflare_api_token (env wins). preflight.sh checks for it. Token NOT written into any file yet. Only `terraform validate` was run for this path; the live test used the env var.

## 2026-10-16 (access finding)
- FINDING: `az login --username lab@... --password` fails with AADSTS50076: MFA is enforced for the shared `lab` account, so students cannot sign in from the CLI with a password. Browser/device-code login needs MFA each time on one shared account. Needs a decision: service principal for the lab, or relax MFA for lab. Not yet changed.
- Added capstone/scripts/login.sh (Way 1 interactive device-code login; Way 2 service principal via config/azure-login.env) and config/azure-login.env.example. Updated README, INSTALL, LAB-GUIDE, TROUBLESHOOTING, INSTRUCTOR and preflight message. Service principal NOT created yet (awaiting user decision); no Azure changes made.
- Open risk: Way 2 (service principal) is untested live. Role assignments made by an SP without Graph read rights may fail; must be tested before sharing.
- Service principal `capstone-lab` created by the user (appId 680513f1-3528-44b7-bf58-e6b278b6eb08): Contributor + Role Based Access Control Administrator on the subscription, 1-year secret saved in capstone/config/azure-login.env (chmod 600). Remove after the course: az ad sp delete --id 680513f1-3528-44b7-bf58-e6b278b6eb08
- `login.sh sp` verified (needs ~5 min for role propagation). Plan as the SP: 43 to add; Cloudflare token read from the values file (scratch copy), no env var.
- First concurrent test attempt (deploy.sh student02 + student12 in one folder) was stopped: student12 hit a local `.terraform` lock collision; student02 stopped after creating empty rg-cap-student02. Also the auto-approve apply was blocked as a blind apply.
- Fixes: scripts now use a per-student TF_DATA_DIR (.tf-data/<student>); deploy.sh now plans, then applies that saved plan.

## 2026-10-16 (final validation)
- Student-style test as the service principal from a clean copy: student02 + student12 deployed (43 resources each), validate.sh ALL PASSED for both, all pod images (backend, frontend, postgres) come from the student's own ACR. Both destroyed (43 each): no rg-cap-student*, no MC_ groups, no soft-deleted Key Vaults, no Cloudflare NS records, no AKS/AppGW running.
- Bugs fixed during validation: validate.sh empty-array crash; per-student TF_DATA_DIR; deploy.sh plan-then-apply saved plan; login.sh both ways; docs for MFA, SP propagation, orphan resource group.
- Deleted scratch copy (held token + SP secret). Real folder has no Cloudflare token; config/azure-login.env holds the SP secret (chmod 600).
- NOT tested: Way 1 (interactive lab-user login with MFA); students on other OS (Windows/WSL, Linux); more than 2 students at once; HTTPS; deck visual rendering.
- After course: az ad sp delete --id 680513f1-3528-44b7-bf58-e6b278b6eb08 ; remove RBAC Administrator from lab user; roll Cloudflare token; terraform destroy in capstone/bootstrap.

## 2026-10-16 (GitHub push)
- GitHub push protection blocked the first push (SP secret in config/azure-login.env, storage keys in bootstrap/terraform.tfstate). Commit was local only.
- Consolidated ALL secrets into ONE git-ignored file: capstone/config/secrets.env (SP login + CLOUDFLARE_API_TOKEN slot, currently empty). Template: config/secrets.env.example (committed). Removed azure-login.env. New scripts/_env.sh loads the token for Terraform; provider no longer reads the token from master-values.yaml.
- .gitignore now covers secrets.env, *.pem, *.key, .terraform, .tf-data, *.tfstate*, *.tfplan, .DS_Store. Untracked bootstrap/terraform.tfstate (kept on disk; needed to destroy bootstrap later).
- Amended the single local commit (now 1fc4f75), expired reflog and gc'd old objects; verified no secrets in history. Pushed to origin main (new branch).
- TODO for user: put the Cloudflare token into config/secrets.env (CLOUDFLARE_API_TOKEN=). Consider rotating SP secret and storage account keys since they briefly sat in a local commit (never reached GitHub).

## 2026-10-16 (demo prep)
- Added spare `instructor` row (index 13) to capstone/config/master-values.yaml for the live demo.
- Wrote capstone/instructorflow.md (step-by-step instructor flow: blockers, day-before, session timeline, plan B, after-course cleanup, tested vs not tested). Not yet committed/pushed.
- preflight for `instructor`: all OK except CLOUDFLARE_API_TOKEN still empty in config/secrets.env (user must add).
