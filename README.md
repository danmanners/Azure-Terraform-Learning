# Azure Deployment with Terraform

This repo is a bit of a brain dump for learning Azure through Terraform.

## Troubleshooting and initializing

I first received this issue when running `terraform init`:

```bash
➜  Azure-Terraform-Learning git:(main) ✗ terraform init

Initializing the backend...
╷
│ Error: storage.NewClient() failed: dialing: google: could not find default credentials. See https://developers.google.com/accounts/docs/application-default-credentials for more information.
│
│
╵
```

Well, that seemed odd. After googling for it, I realize that while I **had** run `gcloud init` for the backend, I hadn't actually authenticated. This next command fixed the issue, and allowed me to run `terraform init` successfully.

```bash
gcloud auth application-default login
```

## Spinning things up

```bash
# Initialize things
terraform init

# Deploy infrastructure
terraform apply
```
