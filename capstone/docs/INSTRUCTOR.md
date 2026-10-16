# Instructor guide

## One-time setup

1. **Quotas** (region `westus3`, already requested for this subscription - verify with `preflight.sh`):

   | Quota | Needed for 12 students + you | Notes |
   |---|---|---|
   | `StandardDsv6Family` vCPUs | 26 (13 x 2, includes the `instructor` demo row) | Students MUST use `Standard_D2s_v6`; other families have 0 |
   | Total Regional vCPUs | 26 + headroom | 190 |
   | `IPv4StandardSkuPublicIpAddresses` | 26 (13 x 2: gateway + cluster outbound) | raised 20 -> 40 |

2. **State storage:** `cd bootstrap && terraform init && terraform apply`.
   This writes `config/backend.hcl` (not a secret, committed to git). Students get the code from GitHub (`git clone`);
   the ONE secrets file `config/secrets.env` is NOT in git - send it to them privately.
   Your day-by-day run sheet is in `instructorflow.md`.

3. **Edit `config/master-values.yaml`** if needed (region, VM size, domain, students).
   `index` must be unique per student. The `instructor` row (index 13) is for your live demo.

4. **Student access.** Students can sign in two ways (both documented in `docs/INSTALL.md`; `scripts/login.sh` does both):
   - **Way 1, interactive:** the shared `lab` account. MFA is enforced on it, so the CLI cannot use a
     password; students use `./scripts/login.sh` (device code + MFA approval). Every sign-in needs an MFA
     approval from whoever owns the account's authenticator - fine for one or two people, awkward for 12.
   - **Way 2, service principal (recommended for 12 students):** no MFA. Create it once:
     ```bash
     SUB=$(az account show --query id -o tsv)
     az ad sp create-for-rbac --name capstone-lab --role Contributor --scopes /subscriptions/$SUB
     az role assignment create --assignee <appId> --role "Role Based Access Control Administrator" --scope /subscriptions/$SUB
     ```
     Wait about 5 minutes before the first login (Azure needs time to apply the roles; an early login says
     "No subscriptions found"). Already done for this course: app `capstone-lab`, appId `680513f1-3528-44b7-bf58-e6b278b6eb08`,
     secret in `config/secrets.env` (valid 1 year).
     Put the printed `appId`, `password` and `tenant` into `config/secrets.env` (copy of `config/secrets.env.example`)
     and share that file privately. Delete the app (`az ad sp delete --id <appId>`) after the course.
   Either identity needs the role assignment permission below.

   The shared `lab` account: The code creates
   role assignments (identity, ACR pull, Key Vault, AKS), so that account needs
   **permission to create role assignments**. `Contributor` alone is NOT enough.
   Give it **Role Based Access Control Administrator** (or User Access Administrator) on the
   subscription. Note this lets anyone using that login grant themselves roles, so remove it
   after the course.

5. **Cloudflare delegation** (so `app.studentNN.lab.collabgigs.com` resolves on the internet):
   - Create a token: Cloudflare -> My Profile -> API Tokens -> Custom -> **Zone > DNS > Edit**,
     only zone `collabgigs.com`, with an expiry of the course length.
   - Paste it into `config/secrets.env` as `CLOUDFLARE_API_TOKEN=...`. The scripts load it automatically. That file is git-ignored: share it with students privately (never through GitHub).
   - **Roll/delete the token after the course.** Anyone with it can edit all DNS in that zone.
   - If you prefer not to share a token: set `enable_cloudflare_delegation: false`. Students then
     use the gateway IP. (Or create one parent zone yourself and delegate once.)

## Running the course
- `./scripts/preflight.sh studentNN` before deploy; `./scripts/validate.sh studentNN` after.
- Deployments are independent (one state file each). 12 at the same time is fine.
- Typical times: deploy ~15 min, destroy ~10 min.

## Cost (approx, westus3, pay-as-you-go - check current prices)
Per student per hour: AKS node D2s_v6 ~$0.10, Application Gateway WAF_v2 ~$0.45,
public IPs ~$0.01, disk/registry/storage pennies. **About $0.6/hour/student - about $7/hour for 12.**
The Application Gateway is the main cost. Destroy at the end of every session.

## Cleaning up
- Each student: `./scripts/destroy.sh studentNN`.
- Find leftovers: `az group list --query "[?starts_with(name,'rg-cap-')].name" -o tsv`
  (the `MC_rg-cap-...` groups belong to AKS and are removed with the cluster).
- Finally remove state storage: `cd bootstrap && terraform destroy`, and delete the Cloudflare token.
- Key Vaults are purged on destroy, so the same student can redeploy immediately.

## Customising
- Different VM size/region: edit `global:` in the master file (check quota first).
- Add a student: add a row with a new unique `index`.
- Swap a module for an Azure Verified Module (AVM): keep the same module inputs/outputs in
  `modules/<name>` and call the AVM from inside it, so the root module does not change.

## Known limits
- HTTP only (no TLS); WAF is on in Prevention mode.
- One node: fine for the lab, not for production. Upgrades would cause downtime.
- ACR Tasks can be blocked on some subscriptions; `build-images.sh` then falls back to local Docker.
