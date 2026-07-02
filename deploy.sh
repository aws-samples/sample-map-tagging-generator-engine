#!/bin/bash
# deploy.sh — One-shot deployment for MAP Tag Generator
# Usage: curl -sL https://raw.githubusercontent.com/aws-samples/sample-map-tagging-generator-engine/main/deploy.sh | bash
set -e

echo "============================================"
echo " MAP Tag Generator — Automated Deployment"
echo "============================================"
echo ""

# Configuration
AWS_REGION=us-east-1
STACK_NAME=map-tag-generator
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DEPLOYMENT_BUCKET_NAME=map-tag-deploy-${ACCOUNT_ID}

echo "AWS Account:  ${ACCOUNT_ID}"
echo "Region:       ${AWS_REGION}"
echo "Stack name:   ${STACK_NAME}"
echo "S3 bucket:    ${DEPLOYMENT_BUCKET_NAME}"
echo ""

# Prompt for admin email
read -p "Enter admin email: " ADMIN_EMAIL
if [ -z "$ADMIN_EMAIL" ]; then
  echo "Error: Admin email is required." && exit 1
fi
echo ""

# Download template
echo "[1/5] Downloading template from GitHub..."
curl -sLO https://raw.githubusercontent.com/aws-samples/sample-map-tagging-generator-engine/main/map-tagging-app-standalone.yaml

# Verify download
if ! head -1 map-tagging-app-standalone.yaml | grep -q "AWSTemplateFormatVersion"; then
  echo "Error: Downloaded file is not a valid CloudFormation template."
  echo "       Check the GitHub repository URL and try again."
  rm -f map-tagging-app-standalone.yaml
  exit 1
fi
echo "       Template verified."

# Create S3 bucket (ignore error if it already exists)
echo "[2/5] Creating deployment bucket..."
aws s3 mb s3://${DEPLOYMENT_BUCKET_NAME} --region ${AWS_REGION} 2>/dev/null || true

# Upload template to S3
echo "[3/5] Uploading template to S3..."
aws s3 cp map-tagging-app-standalone.yaml s3://${DEPLOYMENT_BUCKET_NAME}/map-tagging-app-standalone.yaml --quiet

# Deploy CloudFormation stack
echo "[4/5] Deploying CloudFormation stack (this takes 5-8 minutes)..."
aws cloudformation deploy --template-file map-tagging-app-standalone.yaml --stack-name ${STACK_NAME} --capabilities CAPABILITY_NAMED_IAM --s3-bucket ${DEPLOYMENT_BUCKET_NAME} --region ${AWS_REGION} --parameter-overrides BootstrapAdminEmail=${ADMIN_EMAIL}

# Retrieve and display URL
echo "[5/5] Retrieving application URL..."
FRONTEND_URL=$(aws cloudformation describe-stacks --stack-name ${STACK_NAME} --region ${AWS_REGION} --query "Stacks[0].Outputs[?OutputKey=='FrontendUrl'].OutputValue" --output text)

echo ""
echo "============================================"
echo " Deployment complete!"
echo "============================================"
echo ""
echo " Application URL: ${FRONTEND_URL}"
echo ""
echo " Check your email (${ADMIN_EMAIL}) for a"
echo " temporary password from Amazon Cognito."
echo "============================================"
