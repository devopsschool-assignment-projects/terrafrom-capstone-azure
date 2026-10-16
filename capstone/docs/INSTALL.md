# Install guide

You need these tools on your laptop. Versions shown are the ones the lab was tested with.

| Tool | Why | Tested with |
|---|---|---|
| Azure CLI (`az`) | log in to Azure, build images in ACR | 2.91 |
| Terraform | creates the infrastructure | 1.16 (>= 1.6 works) |
| kubectl | look at your cluster | any recent |
| jq, curl, dig | used by the helper scripts | any |
| Docker (optional) | only needed if ACR Tasks is blocked | any |

## macOS (Homebrew)

```bash
brew install azure-cli terraform kubernetes-cli jq bind
# optional
brew install --cask docker     # or Rancher Desktop
```

## Windows

Best: **WSL2 (Ubuntu)** - follow the Linux steps inside it. The scripts are bash.
Git Bash also works (install Azure CLI, Terraform, jq, kubectl and `dig`/`nslookup` for Windows), but run every command
from the Git Bash window, and `git pull` first: older copies fail with `'.' is not recognized` (Terraform tried to run a
`.sh` script through `cmd.exe`).

## Linux (Ubuntu / Debian)

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install -y jq curl dnsutils unzip
# Terraform: https://developer.hashicorp.com/terraform/install
# kubectl:   https://kubernetes.io/docs/tasks/tools/
```

## Sign in and check

There are **two ways** to sign in. Your instructor tells you which one to use.

**Way 1 - interactive (your own account, or the lab account with MFA)**
```bash
./scripts/login.sh              # same as: az login --use-device-code
```
It prints a code and a web link. Open the link, enter the code, sign in, and approve the
MFA prompt if asked. (A password typed into the terminal does not work when MFA is on.)

**Way 2 - service principal (app id + secret, no browser, no MFA)**
```bash
cp config/secrets.env.example config/secrets.env
# edit config/secrets.env: or just use the secrets.env file the instructor gives you
./scripts/login.sh sp
```

Then check everything:
```bash
az account show --query name -o tsv
terraform version
./scripts/preflight.sh student03 # replace with your id: checks tools, login, quota, token
```

`preflight.sh` verifies: tools installed, Azure login, your id exists in the master file,
`config/backend.hcl` exists, and there is enough **vCPU** and **public IP** quota.

## Files the instructor gives you
- The repository: `git clone git@cotocusin:devopsschool-assignment-projects/terrafrom-capstone-azure.git` (then `cd terrafrom-capstone-azure/capstone`)
- Your student id (for example `student03`)
- `config/secrets.env` (ONE private file with every secret: sign-in details and the Cloudflare token). It is not in GitHub; the instructor sends it privately. Put it in `config/`.
