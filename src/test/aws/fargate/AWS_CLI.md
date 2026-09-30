# Optional Local AWS CLI Setup (Windows)

This document is optional.

Use it only if you need to run AWS commands from your local machine.

You do not need this for initial discovery if CloudShell works in your account.

Primary workflow is in [IMPLEMENT.md](IMPLEMENT.md).

## 1) When You Need Local AWS CLI

Use local AWS CLI when you need one or more of these:

1. Repeatable local scripts for AWS operations
2. Local terminal workflow outside browser
3. Integration with local tooling and automation

## 2) Install AWS CLI v2

### Option A: winget

1. Open PowerShell.
2. Run:

```powershell
winget install --id Amazon.AWSCLI -e
```

3. Close and reopen terminal.
4. Verify:

```powershell
aws --version
```

### Option B: MSI installer

1. Download AWS CLI v2 for Windows from AWS official docs.
2. Run installer.
3. Reopen terminal.
4. Verify:

```powershell
aws --version
```

## 3) Configure Credentials

Run:

```powershell
aws configure
```

Enter:

1. Access key ID
2. Secret access key
3. Region (example: us-east-1)
4. Output format (json)

## 4) Verify Identity and Access

Run:

```powershell
aws sts get-caller-identity
aws ecr describe-repositories
aws ecs list-clusters
aws logs describe-log-groups
aws s3 ls
aws efs describe-file-systems
```

Interpretation:

1. Empty list means access exists but no resources are present.
2. AccessDenied means permission updates are required.

## 5) Troubleshooting

1. Command not found: reopen terminal, then reboot if needed.
2. Unable to locate credentials: rerun aws configure.
3. AccessDenied: capture command and error and request IAM policy changes.
