# Instructor flow: running the Capstone demo

Follow this top to bottom. Times are for a ~2.5 hour session with 12 students.
Everything marked **TESTED** was run end to end on 2026-10-16. Everything marked **NOT TESTED** was not, so have a plan B.

---

## 0. Before anything else (5 min) - blockers

| # | Check | How | Status |
|---|---|---|---|
| 1 | **Cloudflare token is in `config/secrets.env`** | Add `CLOUDFLARE_API_TOKEN=...` (Zone > DNS > Edit, zone `collabgigs.com` only). It is **empty right now**; preflight fails until you add it. | **MUST DO** |
| 2 | You are signed in | `./scripts/login.sh sp` (or `az login`) | TESTED |
| 3 | Preflight is green for your demo id | `./scripts/preflight.sh instructor` | TESTED |
| 4 | Quotas (westus3) | preflight shows Dsv6 vCPUs free >= 2 and public IPs free >= 2. Needs: 26 vCPU, 26 public IPs for 12 students + you | TESTED |
| 5 | Nothing left running from tests | `az aks list -o table` and `az group list --query "[?starts_with(name,'rg-cap-')].name" -o tsv` should be empty | TESTED (clean) |

If you cannot get the Cloudflare token in: set `enable_cloudflare_delegation: false` in `config/master-values.yaml`.
Everything still works, but students open `http://<gateway IP>` instead of the subdomain.

## 1. One day before (15 min)

1. Open `presentation/capstone.pptx` and read every slide. **It was never rendered/visually checked** - look for text that overflows a box.
2. Do a full dry run yourself: `./scripts/deploy.sh instructor` -> `./scripts/validate.sh instructor` -> `./scripts/destroy.sh instructor` (about 35 min, about $0.50).
3. Send students (privately, **not GitHub**): their student id and the file `config/secrets.env`.
4. Send students the repo link, and make sure they can read it (private repos need access):
   `git clone git@cotocusin:devopsschool-assignment-projects/terrafrom-capstone-azure.git`
5. Ask students to install the tools **before** class: `docs/INSTALL.md` (az, terraform, kubectl, jq, curl, dig).
   Windows students use WSL2. **Windows/WSL and Linux laptops were NOT TESTED** (only macOS).

Student ids: `student01` ... `student12`. You use `instructor` (a spare row, index 13).

## 2. 30 minutes before class

1. `git pull` so you have the latest code. Confirm `config/secrets.env` is present (it is git-ignored).
2. `./scripts/login.sh sp` then `./scripts/preflight.sh instructor` - must be all OK.
3. Open in separate browser tabs: Azure portal (resource groups), Cloudflare DNS page, the slide deck.
4. Have a terminal open in `capstone/`.

## 3. The session

### Part A - Introduce (15 min) - slides 1-8
| Slide | Say |
|---|---|
| 1 Title | What they will build in one sentence |
| 2 What you will build | Walk left to right: browser -> DNS -> App Gateway (WAF) -> internal LB -> AKS (frontend, backend, database) |
| 3 Three tiers | Database runs inside the cluster on purpose (no managed DB) |
| 4 Azure services | One line per service |
| 5 One root, ten modules | Open `infra/main.tf` and `modules/network/main.tf` on screen |
| 6 One master file | Open `config/master-values.yaml`; show a student row. "Same code, different row." |
| 7 No passwords | Workload identity: pod -> OIDC token -> Entra ID -> Key Vault |
| 8 Follow one request | The 5 steps |

### Part B - Everyone signs in and checks (10 min) - slide 9
Every student, from the repo folder, with `config/secrets.env` in place:
```bash
./scripts/login.sh sp
./scripts/preflight.sh studentNN
```
Everyone must see all OK before moving on. Typical problems are in `docs/TROUBLESHOOTING.md`.
Wait 5 minutes if the service principal says "No subscriptions found" (only right after creating it; already done).

### Part C - Deploy (about 15-20 min, run it live) 
**You go first on your own screen, students follow:**
```bash
./scripts/deploy.sh studentNN       # you: instructor
```
- It shows the plan (about 43 resources) and then applies it.
- **Staggering:** have students start in groups of 4 (about 2 minutes apart) so the first run of 12 at once is not a surprise. **Only 2 at once was TESTED**, 12 at once was not. Quotas allow all 12.
- While it runs (use this time, ~15 min), do slide 10 and these live demos in a second terminal:
  1. Show state: `az group list --query "[?contains(name,'studentNN')].name" -o tsv`
  2. Show the portal filling up: resource group -> Application Gateway, Key Vault, Container Registry.
  3. Show the Cloudflare DNS page getting 4 NS records for `studentNN.lab` (the delegation).
  4. Open `modules/k8s-app/main.tf` and point at: StatefulSet (database), `managed-csi` (Azure Disk), the internal load balancer annotation.
- Common things to watch: the slow steps are the AKS cluster (~5 min) and Application Gateway (~5 min). That is normal.

### Part D - Validate and use the app (15 min)
```bash
./scripts/validate.sh studentNN
```
Every line should say PASS and end with `ALL CHECKS PASSED`. Then open the URL it prints, `http://app.studentNN.lab.collabgigs.com`.
(If DNS is slow, validate falls back to the gateway IP and tells you.)

Show students:
1. The **blue banner** = a Key Vault secret read by the backend pod with its Entra ID identity.
2. Sign the **guest book**: the message is saved in PostgreSQL.
3. The grey info box: student id, backend pod name, database up, banner source `key-vault`.

### Part E - Explore and break things (30 min) - slide 10
Students do the exercises in `docs/LAB-GUIDE.md`, step 5. You demo the best two:
```bash
az aks get-credentials -g rg-cap-studentNN -n aks-cap-studentNN --admin --overwrite-existing
kubectl -n capstone get pods,svc,pvc
kubectl -n capstone delete pod postgres-0        # reload the page: messages survive (Azure Disk) TESTED
curl "http://app.studentNN.lab.collabgigs.com/?q=<script>alert(1)</script>"   # 403 from the WAF TESTED
```
Also show: `kubectl -n capstone get pods -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}'` - every image comes from the student's own Container Registry (`*.azurecr.io`). TESTED

### Part F - Wrap up and clean up (15 min) - slides 11-12
1. Recap (slide 12).
2. **Every student runs `./scripts/destroy.sh studentNN`.** About 10 minutes. This is what stops the billing.
3. Check nothing is left, from your terminal:
   ```bash
   az group list --query "[?starts_with(name,'rg-cap-student') || starts_with(name,'MC_rg-cap')].name" -o tsv
   az aks list -o table
   ```
   Both must be empty. For a student who left, run `./scripts/destroy.sh studentNN` yourself.

## 4. If something goes wrong (quick plan B)

| Problem | Do |
|---|---|
| One student's deploy fails | Read the last error, find it in `docs/TROUBLESHOOTING.md`, rerun `deploy.sh` (it resumes). |
| "resource group ... already exists" | An earlier run was interrupted. Check it is empty, delete it, rerun. |
| DNS not resolving | Wait 5 min. Meanwhile use the gateway IP (`terraform output app_public_ip` in `infra/`). |
| Quota error | `az vm list-usage -l westus3 -o table`; ask a student to destroy, or move them to another region (needs quota there). |
| Whole class stuck on login | Fall back to a shared browser login (`./scripts/login.sh`) with the lab account: needs MFA approval for each sign-in (**NOT TESTED**, slow for 12). |
| Student never finishes | Destroy their environment yourself after class. |

## 5. After the course (15 min) - do not skip
```bash
# 1. make sure every student environment is gone (see Part F step 3)
# 2. delete the service principal and remove the extra role
az ad sp delete --id 680513f1-3528-44b7-bf58-e6b278b6eb08
az role assignment delete --assignee lab@app9devopsschool.onmicrosoft.com --role "Role Based Access Control Administrator" --scope /subscriptions/092c8f39-7113-46c4-8cce-d26a6afd9f67
# 3. remove the state storage (keeps nothing running or billing)
cd bootstrap && terraform destroy
```
4. In Cloudflare, delete (or roll) the API token and remove any leftover `*.lab` NS records.
5. Delete or rotate the copies of `secrets.env` you sent.
6. Optional: rotate the service principal secret and storage keys first if you ever shared them beyond the class.

## 6. Cost and time cheat sheet
- About **$0.60 per student per hour**, about **$7/hour for 12 students** (list-price estimate; check Cost Management for real numbers).
- A 3-hour session with 12 students is roughly **$20-25**. Forgetting to destroy costs about $170 a day.
- Deploy about 15 min, destroy about 10 min per student (in parallel).

## 7. What is tested and what is not

| Tested end to end (2026-10-16) | Not tested |
|---|---|
| 1 student, then 2 at once, from a clean copy | 12 at once |
| Service principal sign-in (no MFA) | Interactive/MFA sign-in as the shared `lab` user |
| Cloudflare token loaded from a file | Windows (WSL) and Linux laptops |
| Registry images only, WAF 403, Key Vault banner, DB survives pod delete | HTTPS (the lab is HTTP only) |
| Full destroy leaves nothing behind | Rendering the slide deck visually |

Good luck with the demo.
