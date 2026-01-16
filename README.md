# Install the Pre requisits
- 🔵Azure Account (Free one is enough)
- 🔵GitHub Account
- 🔴WSL2->   wsl --install (Run on powershell with administrator mode if on windows)


### Then install the following on WSL (Ubuntu)
- 🔴Azure CLI - https://github.com/Azure/azure-cli  (Log into your azure account)
- 🔴Terraform - https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- 🔴Terraform version manager - https://github.com/tfutils/tfenv
- 🔴Terragrunt version manager - https://github.com/cunymatthieu/tgenv
- 🔴kubectl - https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

## Add the static files
- .gitignore
- empty.yaml
- org.yaml
- terragrunt.hcl

## Then Create the rest inside `subscriptions`
- add `subscription.yaml`