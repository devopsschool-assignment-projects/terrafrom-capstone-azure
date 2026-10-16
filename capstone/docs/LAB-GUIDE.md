# Lab guide (student)

**Goal:** deploy a complete 3-tier application on Azure with Terraform, then prove it works.
**Time:** about 15 minutes of waiting + 30-45 minutes of exploring.
Your instructor gives you a student id such as `student03`. Use it everywhere below.

## Step 0 - Prepare
```bash
cd capstone
./scripts/login.sh          # interactive (browser + MFA)
# or, if the instructor gave you an app id + secret:
#   (put the secrets.env file from the instructor in config/)
#   ./scripts/login.sh sp
./scripts/preflight.sh student03
```
Fix anything marked FAIL (see `docs/INSTALL.md`).

## Step 1 - Look before you deploy (10 min)
Open and read, in this order:
1. `config/master-values.yaml` - find **your** row under `students:`. Notice `index` (your IP range) and `banner`.
2. `infra/main.tf` - the root module. Find the `module "..."` blocks. Which ones depend on others?
3. `modules/network/main.tf` - a small module. Inputs: `variables.tf`. Outputs: `outputs.tf`.

Questions to answer:
- Where does the name `rg-cap-student03` come from?
- Which IP range will your VNet use?
- Why does the `aks` module have `depends_on = [module.identity]`?

## Step 2 - Deploy
```bash
./scripts/deploy.sh student03
```
Terraform builds ~43 resources. While you wait, read `docs/ARCHITECTURE.md`.

**DNS note:** the last module publishes your subdomain by adding 4 `NS` records in
Cloudflare. That needs a Cloudflare token. It is already inside the `config/secrets.env` file the instructor gave you, so you do nothing. It is also used by destroy, because destroy removes the records. If there is no token, the instructor has set `enable_cloudflare_delegation: false` and you will use the
gateway IP instead (see step 4).

## Step 3 - Validate
```bash
./scripts/validate.sh student03
```
It checks the cluster, the three pods, the database disk, DNS, the web app, Key Vault
access and the WAF. Every line should say PASS.

## Step 4 - Use the app
Open the URL printed by deploy (`http://app.student03.lab.collabgigs.com`).
No DNS yet? Use `http://<app_public_ip>` (run `terraform output app_public_ip` in `infra/`).
- The blue banner comes from **Key Vault** (read with the backend's Entra ID identity).
- Sign the guest book - the message is saved in **PostgreSQL** on an Azure Disk.

## Step 5 - Explore your cluster
```bash
az aks get-credentials -g rg-cap-student03 -n aks-cap-student03 --admin --overwrite-existing
kubectl -n capstone get pods,svc,pvc
kubectl -n capstone logs deploy/backend
kubectl -n capstone get svc frontend      # EXTERNAL-IP is the PRIVATE load balancer IP
```
Try these:
1. Delete the database pod: `kubectl -n capstone delete pod postgres-0`. Reload the page. Are your messages still there? Why?
2. Open the Azure portal -> your resource group. Find the Application Gateway, the Key Vault, the registry. Which resource did *Kubernetes* create (hint: look at the `MC_...` resource group)?
3. Change `banner` for your student in `config/master-values.yaml`, run `deploy.sh` again. What changes? (Hint: only the Key Vault secret. Reload the page after a minute.)
4. Attack your own site: `curl "http://<url>/?q=<script>alert(1)</script>"`. What do you get? Which resource said no?

## Stretch exercises
- Add a second backend replica (`replicas` in `modules/k8s-app/main.tf`). Refresh and watch the `Backend pod` name change.
- Create a CronJob that runs `pg_dump` and uploads to the `db-backups` container.
- Add HTTPS to the Application Gateway with a free certificate.
- Switch `waf_mode` to `Detection`. Re-run the attack from exercise 4. What changed?

## Step 6 - Clean up (important!)
```bash
./scripts/destroy.sh student03
```
This deletes everything and stops the cost. Always do this at the end of the day.

## What you learned
Root + child modules, one master values file, remote state, VNet, AKS, ACR, Key Vault,
Entra ID workload identity, Application Gateway + WAF, internal Load Balancer, Azure
Disks, Azure DNS, and running a database in Kubernetes.
