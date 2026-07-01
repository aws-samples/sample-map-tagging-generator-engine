# Threat Model — Automated MAP Tagging & Value Engine

**Version:** 1.1
**Date:** June 29, 2026
**Status:** Current

## System Overview

Serverless web application using Amazon Bedrock (Nova Pro) to generate MAP `map-migrated` tag values and CLI/Terraform commands, and scans for untagged resources via AWS Config. Served via CloudFront with Cognito authentication.

## Trust Boundaries

| Boundary | From | To | Control |
|----------|------|-----|---------|
| TB-1 | Internet | CloudFront | TLS 1.2+, HTTPS redirect |
| TB-2 | CloudFront | S3 | OAC (Origin Access Control), private bucket |
| TB-3 | Internet | API Gateway | Cognito JWT validation |
| TB-4 | API Gateway | Lambda | IAM execution role |
| TB-5 | Lambda | Bedrock | IAM role, model ID restriction |
| TB-6 | Lambda | AWS Config | IAM role, region/account conditions |
| TB-7 | Lambda | STS AssumeRole | Scoped to map-tag-scanner-read-role only |

## Key Threats & Mitigations

### Prompt Injection (Medium → Low residual)
- System prompt hardcoded (not user-controllable)
- Model output validated against hardcoded tag rules
- Output never executed server-side — returned as text only
- No LangChain, agents, or code interpreters

### Cross-Account Access (Medium → Low residual)
- AssumeRole scoped to specific role name only
- ExternalId required for cross-account trust
- Temporary credentials (15 min duration)
- Target account must explicitly deploy the scanner role

### Unauthorized API Access (Medium → Low residual)
- Cognito JWT authorizer on all endpoints
- Admin-only user creation (no self-signup)
- API Gateway rate limiting
- 60-minute token expiry

## Accepted Risks

| Risk | Justification | Controls |
|------|---------------|----------|
| `Resource: *` for config:SelectResourceConfig | AWS platform limitation | Region + account conditions |
| `Resource: *` for sts:AssumeRole | Scoped to specific role name | Role name restriction |
| SQS SSE (not KMS) | Adequate for DLQ metadata | SqsManagedSseEnabled: true |

## AI Safety

- Two-phase architecture: AI extracts parameters → deterministic rules generate values
- Model output is validated JSON — invalid responses rejected
- No model output is executed, stored long-term, or used in network calls
- AI opt-out policy guidance provided for AWS Organizations
