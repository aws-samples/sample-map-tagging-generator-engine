# Automated MAP Tagging & Value Engine

A self-service serverless solution that generates correct `map-migrated` tag values and ready-to-run AWS CLI or Terraform commands for the [AWS Migration Acceleration Program (MAP)](https://aws.amazon.com/migration-acceleration-program/).

## What It Does

- **Tag Value Generator** — enter your MPE ID and credit program, get the correct tag value instantly
- **Wizard Mode** — guided click-through: select services → choose format → get commands (no AI needed)
- **Conversational Mode** — describe your migration in natural language, Amazon Nova Pro generates everything
- **Untagged Resource Scanner** — finds resources missing the `map-migrated` tag via AWS Config
- **Cross-Account Scanning** — scan other AWS accounts using a companion IAM role template
- **Governance Artifacts** — downloadable SCP and Tag Policy for organization-wide enforcement

## Deploy

### Option 1: CloudFormation Console

1. Download `map-tagging-app-standalone.yaml`
2. Go to **AWS Console → CloudFormation → Create Stack → Upload a template file**
3. Upload the YAML file
4. Enter your admin email address
5. Acknowledge IAM capabilities → Submit
6. Wait ~5-8 minutes for `CREATE_COMPLETE`
7. Open the **FrontendUrl** from the Outputs tab

### Option 2: AWS CLI

```bash
# Set variables
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="map-tag-deploy-${ACCOUNT_ID}"
REGION="us-east-1"

# Create S3 bucket for template upload (template is >51 KB)
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Upload template to S3
aws s3 cp map-tagging-app-standalone.yaml s3://${BUCKET_NAME}/map-tagging-app-standalone.yaml

# Deploy stack
aws cloudformation create-stack \
  --stack-name map-tag-generator \
  --template-url https://${BUCKET_NAME}.s3.amazonaws.com/map-tagging-app-standalone.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=BootstrapAdminEmail,ParameterValue=you@example.com \
  --region ${REGION}

# Wait for completion (~5-8 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name map-tag-generator --region ${REGION}
```

Get the URL:
```bash
aws cloudformation describe-stacks --stack-name map-tag-generator \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendUrl'].OutputValue" \
  --output text --region us-east-1
```

## Cross-Account Scanning

To scan untagged resources in other AWS accounts:

1. Deploy `map-tag-scanner-role.yaml` in each target account
2. Provide the **Account ID** where this app is deployed as the `AppAccountId` parameter
3. Copy the **Role ARN** from the stack Outputs
4. In the app, click "Scan Other Accounts" and paste the Role ARN

## Prerequisites

- An active AWS account
- AWS Config enabled in your target region (for the scanner feature)
- IAM permissions for `CAPABILITY_NAMED_IAM` stacks
- A valid email address (Cognito sends a temporary password)

> Amazon Nova Pro model access is auto-enabled during deployment.

## Security

- Amazon Cognito with admin-only user creation (no self-registration)
- TLS 1.2+ enforced, S3 buckets deny non-HTTPS
- KMS encryption for CloudWatch Logs
- Each Lambda has a dedicated least-privilege IAM role
- No IAM credentials accepted or stored — cross-account uses temporary STS sessions
- API Gateway rate limiting (20 req/s, burst 50)

## Clean Up

```bash
aws cloudformation delete-stack --stack-name map-tag-generator
```

> Stack deletion removes all S3 bucket contents. Save any governance files before deleting.

## Files

| File | Description |
|------|-------------|
| `map-tagging-app-standalone.yaml` | The complete solution — deploy this |
| `map-tag-scanner-role.yaml` | Companion template for cross-account scanning |
| `THREAT-MODEL.md` | STRIDE-based security threat model |

## Cost

Less than $10/month for typical usage. Delete the stack when not in use.

## License

All rights reserved.
