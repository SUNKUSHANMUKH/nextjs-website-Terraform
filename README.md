# 🚀 Next.js on AWS — Complete Deployment Guide

[![Deploy](https://github.com/SUNKUSHANMUKH/smart-log-analyzer01/actions/workflows/deploy.yml/badge.svg)](https://github.com/SUNKUSHANMUKH/smart-log-analyzer01/actions/workflows/deploy.yml)
[![CI](https://github.com/SUNKUSHANMUKH/smart-log-analyzer01/actions/workflows/ci.yml/badge.svg)](https://github.com/SUNKUSHANMUKH/smart-log-analyzer01/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/IaC-Terraform_1.7+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Next.js](https://img.shields.io/badge/Frontend-Next.js-000000?logo=next.js)](https://nextjs.org/)

> A complete, production-ready Next.js deployment on AWS. This guide takes you from zero to a live, auto-scaling application — step by step, in order.

---

## 📋 Table of Contents

1. [What You're Building](#-what-youre-building)
2. [Before You Start](#-before-you-start)
3. [Step 1 — Install Required Tools](#step-1--install-required-tools)
4. [Step 2 — Set Up Your AWS Account](#step-2--set-up-your-aws-account)
5. [Step 3 — Clone & Configure the Repo](#step-3--clone--configure-the-repo)
6. [Step 4 — Prepare Your Next.js App](#step-4--prepare-your-nextjs-app)
7. [Step 5 — Bootstrap AWS Resources](#step-5--bootstrap-aws-resources)
8. [Step 6 — Set GitHub Secrets](#step-6--set-github-secrets)
9. [Step 7 — Deploy Infrastructure with Terraform](#step-7--deploy-infrastructure-with-terraform)
10. [Step 8 — Trigger Your First Deployment](#step-8--trigger-your-first-deployment)
11. [Step 9 — Verify Everything is Working](#step-9--verify-everything-is-working)
12. [Architecture Reference](#-architecture-reference)
13. [Project Structure](#-project-structure)
14. [GitHub Actions Workflows](#-github-actions-workflows)
15. [Critical Config Notes](#-critical-config-notes-dont-skip)
16. [Common Issues & Fixes](#-common-issues--fixes)
17. [Security Checklist](#-security-checklist)
18. [Monthly Cost Estimate](#-monthly-cost-estimate)

---

## 🏗 What You're Building

A production-grade Next.js application hosted on AWS with:

- **Auto-scaling containers** via ECS Fargate — no servers to manage
- **Custom domain + HTTPS** via Route 53 and ACM
- **CDN** via CloudFront — fast global delivery
- **API protection** via API Gateway — rate limiting, auth, CORS
- **Background jobs** via Lambda + SQS — decoupled async processing
- **Database** via RDS PostgreSQL + ElastiCache Redis
- **Fully automated CI/CD** — push to `main`, it deploys itself

```
  Your Browser
       │
       ▼
  Route 53  ──────────────────────────────────────────────────
  (DNS)                                                       │
       │                                               Terraform
       ▼                                               manages all
  CloudFront (CDN + WAF)                                      │
       │                                               GitHub Actions
       ├── Static files (JS/CSS/images) ──► S3         deploys app
       │
       └── Dynamic requests (pages/API)
                    │
                    ▼
             API Gateway
             (HTTP API — auth, rate limiting, CORS)
                    │
                    ▼
               ALB (Load Balancer)
               (health checks, routing)
                    │
                    ▼
          ┌─────────────────────┐
          │   ECS Fargate       │
          │  ┌───────────────┐  │
          │  │  Next.js :3000│  │ ← scales up/down automatically
          │  │  Next.js :3000│  │
          │  └───────────────┘  │
          └─────────────────────┘
                    │
         ┌──────────┼──────────┐
         ▼          ▼          ▼
       RDS      ElastiCache  Secrets Manager
    (Postgres)   (Redis)     (passwords/keys)

  Background work:
  Lambda ──► SQS queue ──► SNS notifications
```

---

## ✅ Before You Start

Make sure you have:

- [ ] An **AWS account** (with billing alerts recommended)
- [ ] A **GitHub account**
- [ ] A **registered domain name** (for Route 53 — or use an AWS-generated URL initially)
- [ ] Basic familiarity with terminal/command line
- [ ] ~30–60 minutes of time

> 💡 **Region:** This guide uses `ap-south-1` (Mumbai). It's the closest AWS region to India and significantly cheaper than `us-east-1` for Indian users.

---

## Step 1 — Install Required Tools

Install these tools in order on your local machine.

### Node.js 20 LTS

```bash
# Using nvm (recommended — lets you switch Node versions)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc   # or ~/.zshrc if using zsh

nvm install 20
nvm use 20

# Verify
node --version   # should print v20.x.x
```

### Docker Desktop

Download from [docker.com/get-started](https://www.docker.com/get-started) and install for your OS.

```bash
# Verify Docker is running
docker --version   # should print Docker version 24+
docker ps          # should return an empty table (not an error)
```

### AWS CLI v2

```bash
# macOS
brew install awscli

# Ubuntu/Debian
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Verify
aws --version   # should print aws-cli/2.x.x
```

### Terraform (via tfenv)

```bash
# Install tfenv — manages Terraform versions, prevents version mismatch issues
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install and pin Terraform 1.7
tfenv install 1.7.5
tfenv use 1.7.5

# Verify
terraform --version   # should print Terraform v1.7.5
```

---

## Step 2 — Set Up Your AWS Account

### 2a. Configure AWS CLI

```bash
aws configure
# AWS Access Key ID:     → paste your access key
# AWS Secret Access Key: → paste your secret key
# Default region name:   → ap-south-1
# Default output format: → json
```

> ⚠️ **Never use root credentials here.** Create an IAM user (`ci-deployer`) with programmatic access only. See [IAM user guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html).

### 2b. Enable MFA on your root account

1. Go to AWS Console → **IAM** → **Security credentials**
2. Click **Activate MFA** and follow the steps

Do this before anything else — it protects your entire account.

### 2c. Create the IAM deploy user

```bash
# Create the user
aws iam create-user --user-name ci-deployer

# Create access keys — save these, shown only once
aws iam create-access-key --user-name ci-deployer

# Attach required policies
aws iam attach-user-policy --user-name ci-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess

aws iam attach-user-policy --user-name ci-deployer \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

aws iam attach-user-policy --user-name ci-deployer \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
```

> 🔒 In production, replace these with a custom minimal-permission policy. The managed policies above are fine to get started.

---

## Step 3 — Clone & Configure the Repo

```bash
# Clone the repository
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Install app dependencies
cd app && npm ci && cd ..
```

Open `infra/variables.tf` and update these values:

```hcl
variable "project_name" {
  default = "myproject"       # ← change to your project name
}

variable "aws_region" {
  default = "ap-south-1"     # ← change if using a different region
}

variable "domain_name" {
  default = "yourdomain.com" # ← change to your actual domain
}
```

---

## Step 4 — Prepare Your Next.js App

Two things **must** be done before the app will work in Docker on AWS.

### 4a. Enable standalone output — `next.config.js`

```js
/** @type {import('next').NextConfig} */
module.exports = {
  output: 'standalone',
}
```

> ❌ Without this line, your Docker image will be 500 MB+ or fail to start entirely.

### 4b. Add the health check endpoint

Create the file `app/src/app/api/health/route.ts`:

```ts
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json(
    { status: 'ok', timestamp: new Date().toISOString() },
    { status: 200 }
  )
}
```

> ❌ Without this file, the AWS Load Balancer thinks your app is down and continuously kills and restarts your containers.

### 4c. Test locally before deploying

```bash
cd app

# Verify the app builds
npm run build

# Test Docker image locally
docker build -t myapp-test .
docker run -p 3000:3000 myapp-test
```

Open these URLs and confirm they both work:
- `http://localhost:3000` — your app loads
- `http://localhost:3000/api/health` — returns `{"status":"ok"}`

If both work locally, you're ready to deploy.

---

## Step 5 — Bootstrap AWS Resources

These two resources must be created **manually before Terraform can run**. Terraform stores its own state here, so it can't create them itself.

### 5a. Create the Terraform state S3 bucket

```bash
# Replace YOUR_ACCOUNT_ID with your actual AWS account ID
# Find it with: aws sts get-caller-identity --query Account --output text

aws s3api create-bucket \
  --bucket myproject-tf-state-YOUR_ACCOUNT_ID \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket myproject-tf-state-YOUR_ACCOUNT_ID \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket myproject-tf-state-YOUR_ACCOUNT_ID \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block all public access
aws s3api put-public-access-block \
  --bucket myproject-tf-state-YOUR_ACCOUNT_ID \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 5b. Create the Terraform lock table

```bash
aws dynamodb create-table \
  --table-name tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 5c. Update `infra/backend.tf` with your bucket name

```hcl
terraform {
  backend "s3" {
    bucket         = "myproject-tf-state-YOUR_ACCOUNT_ID"  # ← your bucket name here
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tf-lock"
    encrypt        = true
  }
}
```

---

## Step 6 — Set GitHub Secrets

GitHub Actions needs your AWS credentials to deploy. Never hardcode these in files.

1. Go to your GitHub repo
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add each of these:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | From Step 2c — the `ci-deployer` access key |
| `AWS_SECRET_ACCESS_KEY` | From Step 2c — the `ci-deployer` secret key |
| `AWS_REGION` | `ap-south-1` |
| `ECR_REGISTRY` | `<your-account-id>.dkr.ecr.ap-south-1.amazonaws.com` |
| `ECR_REPOSITORY` | `myproject/nextjs` |

---

## Step 7 — Deploy Infrastructure with Terraform

```bash
cd infra

# 1. Initialise — downloads providers, connects to your S3 backend
terraform init

# 2. Preview what will be created (no changes yet)
terraform plan

# 3. Apply — creates all AWS resources
terraform apply
# Type 'yes' when prompted
```

This creates ~47 AWS resources and takes about 10–15 minutes. When it finishes:

```
Apply complete! Resources: 47 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name     = "myproject-alb-123456.ap-south-1.elb.amazonaws.com"
api_gateway_url  = "https://abc123.execute-api.ap-south-1.amazonaws.com"
cloudfront_url   = "https://d1234abcd.cloudfront.net"
```

Save these output URLs — you'll use them to verify the deployment.

---

## Step 8 — Trigger Your First Deployment

ECS needs an initial Docker image in ECR before it can start any tasks. Push it manually once:

```bash
# Log in to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  <your-account-id>.dkr.ecr.ap-south-1.amazonaws.com

# Build and push the initial image
cd app
IMAGE_TAG=$(git rev-parse --short HEAD)
ECR_URI=<your-account-id>.dkr.ecr.ap-south-1.amazonaws.com/myproject/nextjs

docker build -t $ECR_URI:$IMAGE_TAG .
docker push $ECR_URI:$IMAGE_TAG
docker tag $ECR_URI:$IMAGE_TAG $ECR_URI:latest
docker push $ECR_URI:latest
```

After this initial push, **every future deployment is fully automatic**:

```bash
# Make changes, commit, push — that's it
git add .
git commit -m "feat: my changes"
git push origin main
# GitHub Actions builds, pushes to ECR, and deploys to ECS automatically
```

---

## Step 9 — Verify Everything is Working

### Check ECS tasks are running

```bash
aws ecs describe-services \
  --cluster myproject-cluster \
  --services myproject-service \
  --query 'services[0].{Running:runningCount,Desired:desiredCount,Status:status}'

# Expected: { "Running": 2, "Desired": 2, "Status": "ACTIVE" }
```

### Check the health endpoint

```bash
# Use the ALB DNS name from terraform output
curl http://myproject-alb-123456.ap-south-1.elb.amazonaws.com/api/health

# Expected: {"status":"ok","timestamp":"2025-..."}
```

### Check GitHub Actions ran successfully

Go to your repo → **Actions** tab → latest workflow run. All steps should show ✅.

### Access your app

| URL | What it is |
|-----|-----------|
| `https://yourdomain.com` | Your app via Route 53 + CloudFront |
| `https://d1234abcd.cloudfront.net` | CloudFront URL (works before DNS propagates) |
| `http://myproject-alb-123456...amazonaws.com` | Direct ALB URL (for testing only) |

---

## 📐 Architecture Reference

### AWS Services & Their Roles

| Service | Role | Key Config |
|---------|------|------------|
| **ECR** | Docker image registry | `image_tag_mutability = IMMUTABLE`, scan on push |
| **ECS Fargate** | Runs containers | `launch_type = FARGATE`, private subnets |
| **ALB** | Load balancer | `target_type = ip` (required for Fargate) |
| **API Gateway** | API routing layer | HTTP API type, VPC Link to ALB |
| **Route 53** | DNS | A/AAAA alias records to CloudFront |
| **ACM** | TLS certificates | DNS validation, covers apex + www |
| **CloudFront** | CDN + WAF | WAF managed rules, S3 origin for static assets |
| **Lambda** | Background functions | SQS event source trigger |
| **SQS** | Message queue | Decouples app from background jobs |
| **RDS PostgreSQL** | Primary database | Multi-AZ, private subnet, secret rotation |
| **ElastiCache Redis** | Cache layer | Private subnet, in-transit encryption |
| **Secrets Manager** | All credentials | Auto-rotation on RDS credentials |
| **CloudWatch** | Logs + metrics + alarms | 90-day retention, SNS alerts |
| **X-Ray** | Distributed tracing | API Gateway + Lambda instrumented |
| **GuardDuty** | Threat detection | Always-on, SNS on HIGH findings |
| **CloudTrail** | Audit log | All API calls logged to S3 |
| **WAF** | Web firewall | Rate limiting + AWS Managed Rules |

---

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── ci.yml          # Runs on every PR: lint, test, Docker build check
│       └── deploy.yml      # Runs on push to main: build → ECR → ECS
│
├── app/                    # ← Your Next.js app lives here
│   ├── Dockerfile          # Multi-stage build, non-root user
│   ├── .dockerignore
│   ├── next.config.js      # Must have output: 'standalone'
│   ├── package.json
│   └── src/
│       └── app/
│           └── api/
│               └── health/
│                   └── route.ts   # Required for ALB health checks
│
├── infra/                  # ← All Terraform code lives here
│   ├── backend.tf          # S3 remote state config
│   ├── main.tf             # Root module — calls all child modules
│   ├── variables.tf        # Inputs (project name, region, domain)
│   ├── outputs.tf          # Outputs (URLs, ARNs)
│   └── modules/
│       ├── vpc/            # VPC, subnets, NAT, Flow Logs
│       ├── ecr/            # Container registry, lifecycle, scanning
│       ├── ecs/            # ECS cluster, service, task definition
│       ├── alb/            # Load balancer, target group, listeners
│       ├── api_gateway/    # HTTP API, VPC Link, routes, throttling
│       ├── lambda/         # Lambda functions, SQS trigger, IAM
│       ├── rds/            # PostgreSQL, subnet group, backups
│       └── route53/        # Hosted zone, ACM cert, DNS records
│
└── README.md
```

---

## 🔄 GitHub Actions Workflows

### CI — every Pull Request

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [main]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: app/package-lock.json

      - name: Install dependencies
        run: npm ci
        working-directory: ./app

      - name: Lint
        run: npm run lint
        working-directory: ./app

      - name: Test
        run: npm test -- --passWithNoTests
        working-directory: ./app

      - name: Docker build check
        run: docker build -t test-build ./app
        # Validates the Dockerfile on every PR — no image is pushed
```

### Deploy — push to `main`

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker image
        run: |
          IMAGE_TAG=${{ github.sha }}
          docker build \
            -t ${{ secrets.ECR_REGISTRY }}/${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG ./app
          docker push \
            ${{ secrets.ECR_REGISTRY }}/${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster myproject-cluster \
            --service myproject-service \
            --force-new-deployment

      - name: Wait for deployment to stabilise
        run: |
          aws ecs wait services-stable \
            --cluster myproject-cluster \
            --services myproject-service
        # Blocks the pipeline until ECS confirms the new tasks are healthy.
        # If your app is broken, this step fails and you know immediately.
```

---

## 🔑 Critical Config Notes (Don't Skip)

### 1. Standalone output in `next.config.js`

```js
module.exports = {
  output: 'standalone',
}
```

| Without this | With this |
|-------------|-----------|
| Image is 400–600 MB | Image is 80–120 MB |
| `server.js` is missing | Starts with `node server.js` |
| Container fails to start | Starts in ~2 seconds |

### 2. Health check route — required for ALB

```ts
// app/src/app/api/health/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ status: 'ok' }, { status: 200 })
}
```

The ALB sends GET `/api/health` every 30 seconds. Anything other than HTTP 200 marks your task unhealthy → it gets killed → your app is never reachable.

### 3. ALB target group — must use `target_type = "ip"`

```hcl
resource "aws_lb_target_group" "app" {
  target_type = "ip"   # NOT "instance" — Fargate uses awsvpc networking
}
```

Using `instance` causes 502 errors because there are no EC2 instances to route to.

### 4. Store secrets in Secrets Manager — not plain env vars

```hcl
# ❌ Wrong — visible in AWS Console, CloudTrail, and task logs
environment = [
  { name = "DB_PASSWORD", value = "mypassword123" }
]

# ✅ Correct — fetched securely from Secrets Manager at task startup
secrets = [
  { name = "DB_PASSWORD", valueFrom = "arn:aws:secretsmanager:ap-south-1:..." }
]
```

### 5. ECS execution role must have ECR pull permission

```hcl
resource "aws_iam_role_policy_attachment" "ecr_pull" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

Without this, ECS cannot pull from ECR → `CannotPullContainerError` on every task start.

---

## ⚠️ Common Issues & Fixes

### ECS tasks keep restarting

**Symptom:** Tasks start, run 30 seconds, stop. Repeats endlessly.

**Cause:** ALB health check is failing.

**Fix:**
1. Confirm `/api/health` route exists and returns HTTP 200
2. Verify port 3000 is open in the ECS task security group from the ALB
3. Check health check path is `/api/health` in the ALB target group

```bash
# See why the task stopped
aws ecs describe-tasks \
  --cluster myproject-cluster \
  --tasks $(aws ecs list-tasks --cluster myproject-cluster --query 'taskArns[0]' --output text) \
  --query 'tasks[0].stoppedReason'
```

---

### `CannotPullContainerError`

**Cause A:** ECS execution role is missing `AmazonEC2ContainerRegistryReadOnly` → add the policy.

**Cause B:** ECS tasks in a private subnet with no NAT Gateway → ECR is unreachable.

```bash
# Check NAT Gateway exists and is in 'available' state
aws ec2 describe-nat-gateways \
  --filter Name=state,Values=available \
  --query 'NatGateways[*].{ID:NatGatewayId,Subnet:SubnetId}'
```

---

### `terraform init` backend error

**Symptom:** `Error: Failed to get existing workspaces`

**Cause:** S3 bucket doesn't exist yet.

**Fix:** Complete Step 5a to create the bucket, then re-run `terraform init`.

---

### ALB 502 Bad Gateway

**Cause:** `target_type` is set to `instance` instead of `ip`.

**Fix:** In `infra/modules/alb/main.tf`, set `target_type = "ip"` and run `terraform apply`.

---

### ACM certificate stuck `PENDING_VALIDATION`

**Cause:** DNS CNAME validation records were not added to Route 53.

**Fix:**

```bash
# See what CNAME records need to be added
aws acm describe-certificate \
  --certificate-arn <your-cert-arn> \
  --query 'Certificate.DomainValidationOptions[*].ResourceRecord'
```

Add the CNAME records shown to Route 53. Terraform should do this automatically if the hosted zone is in the same account — check your `route53` module.

---

### Tasks fail to start (private subnet, no internet)

**Symptom:** `ResourceInitializationError: unable to pull secrets or registry auth`

**Cause:** Private subnet route table has no route to the internet via NAT Gateway.

**Fix:** Ensure the private route table has `0.0.0.0/0 → nat-gateway-id`. Run `terraform apply` after updating.

---

### API Gateway 403 Forbidden

**Cause:** JWT authorizer audience or issuer is misconfigured, or CORS is not enabled.

**Fix:**
1. Check `audience` and `issuer` in your JWT authorizer config match your identity provider
2. Enable CORS on the HTTP API with `allow_origins = ["*"]` during development

---

## 🔐 Security Checklist

Run through this before going live in production.

**Network**
- [ ] ECS tasks are in **private subnets** — not publicly accessible
- [ ] ALB security group only accepts traffic from the **CloudFront managed prefix list**
- [ ] RDS and ElastiCache are in **private subnets** with `publicly_accessible = false`
- [ ] VPC Flow Logs are **enabled** and shipping to CloudWatch

**IAM & Secrets**
- [ ] No `"*"` wildcard in any production IAM policy Action or Resource
- [ ] Separate **execution role** (ECR + CloudWatch) and **task role** (app permissions only)
- [ ] All credentials in **Secrets Manager** — none in task definition environment vars
- [ ] Secret rotation **enabled** for RDS master credentials

**Application**
- [ ] WAF **attached** to CloudFront with AWS Managed Rules enabled
- [ ] WAF rate limiting: max 1000 requests per 5 minutes per IP
- [ ] ECR image scanning on push **enabled**
- [ ] HTTPS redirect enforced at CloudFront and ALB listener level
- [ ] CloudTrail **enabled** — logs to dedicated S3 bucket
- [ ] GuardDuty **enabled**
- [ ] CloudWatch billing alarm set at **$150/month** → SNS email

---

## 💰 Monthly Cost Estimate

> Region: `ap-south-1` (Mumbai) · Moderate traffic · 24/7 uptime

| Service | Configuration | Monthly (USD) |
|---------|---------------|:-------------:|
| ECS Fargate | 2 tasks · 0.5 vCPU · 1 GB · 24/7 | ~$18 |
| ALB | 1 load balancer | ~$18 |
| RDS PostgreSQL | db.t3.micro · Multi-AZ | ~$28 |
| ElastiCache Redis | cache.t3.micro | ~$13 |
| WAF | 1 web ACL + AWS Managed Rules | ~$8 |
| NAT Gateway | 1 AZ · 10 GB processed | ~$5 |
| CloudWatch | Logs + metrics + alarms | ~$5 |
| Secrets Manager | 5 secrets | ~$2.50 |
| CloudFront | 10 GB transfer out | ~$0.85 |
| API Gateway | HTTP API · 1M requests | ~$1 |
| Lambda + SQS + SNS | 1M invocations | ~$0.60 |
| S3 + ECR + Route 53 | Storage + queries | ~$3 |
| DynamoDB (TF lock) | On-demand · minimal use | ~$0.25 |
| **Total** | | **~$104/month** |

### Save money

| Change | Monthly saving |
|--------|:-------------:|
| Use `FARGATE_SPOT` for worker tasks | ~$12 |
| Switch RDS to Single-AZ in dev | ~$14 |
| Set ECR lifecycle policy (keep last 10 images) | Storage creep prevention |
| Set `reserved_concurrency` on Lambda | Runaway cost prevention |

> 💡 **Set a billing alarm** so you're notified before costs spike:
> ```bash
> aws cloudwatch put-metric-alarm \
>   --alarm-name billing-alert-150 \
>   --metric-name EstimatedCharges \
>   --namespace AWS/Billing \
>   --statistic Maximum \
>   --period 86400 \
>   --threshold 150 \
>   --comparison-operator GreaterThanThreshold \
>   --alarm-actions arn:aws:sns:us-east-1:<account-id>:billing-alerts \
>   --dimensions Name=Currency,Value=USD
> ```

---

## 🤝 Contributing

1. Create a branch: `git checkout -b feat/your-feature`
2. Make your changes
3. Verify locally: `npm run lint && npm test`
4. Push and open a pull request — CI runs automatically
5. All CI checks must be green before merging
6. Once merged to `main`, GitHub Actions deploys to production automatically

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

---

*Full architecture document with detailed Terraform module code and deployment phases: [`docs/architecture_guide.docx`](docs/architecture_guide.docx)*
