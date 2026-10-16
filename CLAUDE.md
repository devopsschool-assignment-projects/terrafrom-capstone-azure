# Training Azure Project

Azure account used for training: each of 15 students creates 1 AKS cluster with 2 nodes.

## RULES
- Record every change made to Azure (or this directory) in `changes.md` (append, newest last, with date).
- Keep `infra-spec.md` as the current-state spec of the infrastructure/quotas. Update it whenever state changes.
- Keep this file (`CLAUDE.md`) updated with rules and context so work migrates to a new laptop.
- Confirm with the user before creating, changing or deleting anything on the subscription.
- Prefer read-only checks first.

## Context
- Azure CLI (`az`) is installed and signed in as app9@devopsschool.com (re-run `az login` on a new laptop).
- Subscription: Pay-As-You-Go - new (`092c8f39-7113-46c4-8cce-d26a6afd9f67`), tenant `f34c8fc4-16b8-4de3-8110-45904e3b1d1a`.
- `az quota` extension is installed and `Microsoft.Quota` provider is registered (needed for quota requests).
- Chosen region: westus3. Chosen node VM size: Standard_D2s_v6 (D2s_v3 is deprecated for quota; DSv5 request failed).

## Files
- `infra-spec.md` - current quotas, sizing, student instructions
- `changes.md` - chronological log of changes

## Capstone lab
- Code: /Users/rajesh/training/capstone (see its README.md). One master file: capstone/config/master-values.yaml.
- State storage account stcaptf6o328 (rg-cap-tfstate); backend config in capstone/config/backend.hcl.
- Cloudflare token is NEVER stored; pass via TF_VAR_cloudflare_api_token.
- Always plan -out and review before apply (blind apply gets blocked).
