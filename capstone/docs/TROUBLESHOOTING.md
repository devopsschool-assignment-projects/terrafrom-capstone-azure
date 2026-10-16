# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `AADSTS50076 ... must use multi-factor authentication` | You tried `az login --username ... --password` on an MFA account | Use `./scripts/login.sh` (browser + MFA) or `./scripts/login.sh sp` |
| `login.sh sp`: `AZURE_CLIENT_ID is not set` | `config/secrets.env` missing or empty | Put the `secrets.env` file from the instructor in `config/` (template: `config/secrets.env.example`) |
| `login.sh sp`: `No subscriptions found` | Service principal roles not active yet | Wait 5 minutes and run again |
| `AADSTS7000215 invalid client secret` | Wrong or expired secret | Ask the instructor for a new secret |
| `preflight` says not enough vCPU quota | Another student has the quota, or wrong VM size | Ask the instructor; use `Standard_D2s_v6` only |
| `Error: ... AuthorizationFailed ... roleAssignments/write` | The login cannot create role assignments | Instructor: grant *Role Based Access Control Administrator* (docs/INSTRUCTOR.md) |
| `student_id ... is not listed in config/master-values.yaml` | Typo in the id | Use the exact id from the instructor |
| `Error acquiring the state lock` | Another run for the SAME student is active | Wait, or `terraform force-unlock <id>` (only if you are sure) |
| `QuotaExceeded` / `PublicIPCountLimitReached` | Subscription limit | Instructor requests more quota |
| ACR build fails with `TasksOperationsNotAllowed` | ACR Tasks blocked | Script falls back to Docker automatically - start Docker |
| `Key Vault ... 403 Forbidden` while creating secrets | Role takes time to apply | Run `./scripts/deploy.sh` again |
| Page says `banner source: fallback` | Pod cannot read Key Vault yet | Wait 1-2 min (role propagation), reload. Then `kubectl -n capstone logs deploy/backend` |
| `validate`: DNS check fails | NS records not published/propagated | Wait 5 min; check Cloudflare token was set; use the gateway IP meanwhile |
| Gateway returns `502` | Backend pool unhealthy | `kubectl -n capstone get pods`; wait for pods Ready; `kubectl -n capstone get svc frontend` must show `10.X.0.100` |
| Pods `Pending` | Not enough CPU on the single node | `kubectl describe pod ...`; do not add extra replicas beyond 2 |
| `ImagePullBackOff` | Image not in ACR or AcrPull not active | `az acr repository list -n <acr>`; rerun deploy |
| `kubectl` asks for device login | Entra login (kubelogin) | Use `az aks get-credentials ... --admin`, or install kubelogin |
| Destroy fails on `cloudflare_record` | Token missing or expired | Put a valid `CLOUDFLARE_API_TOKEN` in `config/secrets.env` and run destroy again |
| `a resource with the ID ... rg-cap-studentNN already exists` | An earlier deploy was interrupted, leaving an empty resource group | Check it is empty (`az resource list -g rg-cap-studentNN`), delete it (`az group delete -n rg-cap-studentNN`), run deploy again |
| Destroy hangs on the resource group | Something still attached | Run `./scripts/destroy.sh` again; check the portal |

## Useful commands
```bash
kubectl -n capstone get pods,svc,pvc,events --sort-by=.lastTimestamp
kubectl -n capstone logs deploy/backend --tail=50
kubectl -n capstone exec -it postgres-0 -- psql -U capstone -d capstone -c 'select * from messages;'
cd infra && terraform output
dig +short app.student03.lab.collabgigs.com @1.1.1.1
```
