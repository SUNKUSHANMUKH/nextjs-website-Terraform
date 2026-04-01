#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# bootstrap.sh
# Run this ONCE before `terraform init` to create the remote state backend.
# Terraform cannot create its own state bucket — this must exist first.
# ─────────────────────────────────────────────────────────────────────────────
set -e

REGION="ap-south-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="myproject-tf-state-${ACCOUNT_ID}"
TABLE_NAME="tf-lock"

echo ""
echo "Bootstrap: AWS account  → $ACCOUNT_ID"
echo "Bootstrap: Region       → $REGION"
echo "Bootstrap: State bucket → $BUCKET_NAME"
echo "Bootstrap: Lock table   → $TABLE_NAME"
echo ""

# ── S3 bucket ─────────────────────────────────────────────────────────────────
echo "Creating S3 state bucket..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "✅ S3 bucket created: $BUCKET_NAME"

# ── DynamoDB lock table ────────────────────────────────────────────────────────
echo "Creating DynamoDB lock table..."
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "✅ DynamoDB table created: $TABLE_NAME"

# ── Update backend.tf automatically ───────────────────────────────────────────
sed -i "s/myproject-tf-state-YOUR_ACCOUNT_ID/$BUCKET_NAME/g" infra/backend.tf

echo ""
echo "✅ bootstrap.sh complete. backend.tf has been updated automatically."
echo ""
echo "Next step:"
echo "  cd infra && terraform init"
echo ""
