# terraform-aws-webapp-infra

<img src="aws_architecture_corrected (1).svg" alt="AWS architecture diagram" width="900"/>

Lightweight Terraform project to provision AWS infrastructure for a simple web application.

## What it does
- Provisions core AWS resources required to run a single-instance web app (VPC, subnets, security groups, EC2, etc.)
- Uses the included user-data scripts to configure the instance on boot (`userdata.sh`, `userdata1.sh`).

## Repository files
- [main.tf](main.tf) — resource definitions and module wiring.
- [providers.tf](providers.tf) — provider configuration (AWS region, credentials source).
- [userdata.sh](userdata.sh) — primary instance bootstrap script.
- [userdata1.sh](userdata1.sh) — alternate/additional bootstrap script.

## Prerequisites
- Install Terraform (recommended >= 1.0). See https://www.terraform.io/downloads
- Configure AWS credentials via `aws configure` or environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_PROFILE`).

## Quick start
1. Initialize the workspace:

```
terraform init
```

2. (Optional) Inspect the planned changes:

```
terraform plan
```

3. Apply the changes:

```
terraform apply
```

Use `-var 'name=value'` or a `terraform.tfvars` file to pass variables if the configuration expects them.

## Accessing the instance
If the configuration outputs a public IP (e.g. `public_ip`), connect with SSH using the key pair specified in the configuration:

```
ssh -i path/to/key.pem ec2-user@<public_ip>
```

## Cleanup
To remove all created resources:

```
terraform destroy
```

## Notes
- This configuration stores state locally by default unless a remote backend is configured in `backend` blocks in the Terraform files.
- Review and customize `userdata.sh` / `userdata1.sh` before applying in production.

If you'd like, I can: initialize Terraform here, add a `.gitignore` for `.terraform` and state files, or commit this README. Which should I do next?
