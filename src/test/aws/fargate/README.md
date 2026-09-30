# AWS Docker Plan for OELS k6 Clients

This guide outlines the plan for running containers using AWS Fargate.

This will be the default architecture unless blocked by policy or existing standards:

1. ECR for image storage
2. ECS Fargate for runtime
3. CloudWatch Logs for logs
4. EFS for mounted filesystem persistence, or S3 for artifact storage

Why this is a good default:

- Minimal infrastructure management
- Per-task CPU and memory sizing
- Strong fit for on-demand workloads

## Prerequisites

Before moving forward you should check the following by completing this section of the guide.
This will ensure the following items are known to be good:

- Learn what your AWS account can do.
- Confirm what services you can access right now.
- Prepare to run containers with on-demand behavior.

## Terminology

### Acronyms

- ARN: Amazon Resource Name - Unique identifier string for AWS resources and identities.
- AWS: Amazon Web Services - Cloud platform used to host and run infrastructure and services.
- CLI: Command Line Interface - Text-based way to run commands instead of clicking in the UI.
- ECR: Elastic Container Registry - AWS image registry used to store and retrieve container images.
- ECS: Elastic Container Service - AWS service used to run and manage containers.
- ECS Exec: ECS Execute Command - Feature that opens an interactive shell in a running ECS task.
- EFS: Elastic File System - Shared filesystem storage that can be mounted into containers.
- IAM: Identity and Access Management - AWS service for users, roles, and permissions.
- S3: Simple Storage Service - Object storage used for files, logs, and artifacts.
- STS: Security Token Service - AWS service that returns identity/session details for the current login.

### Key Terms

- Account ID: 12-digit AWS account number used to identify the target account.
- AWS Console: AWS website dashboard in your browser [https://console.aws.amazon.com](https://console.aws.amazon.com).
- CloudShell: Browser-based terminal inside AWS Console.
- Cluster: Logical ECS grouping where tasks and services run.
- Cluster ARN: Unique ID string for an ECS cluster, returned by commands like `aws ecs list-clusters`.
- Container Image: Packaged application artifact (code plus runtime) stored in ECR and run by ECS.
- Fargate: Serverless compute option for ECS so you do not manage servers.
- Launch Type: How ECS runs tasks, usually `FARGATE` or `EC2`.
- Log Group: CloudWatch Logs container that holds related log streams.
- Region: Geographic AWS location where resources run, such as `us-east-1`.
- Repository: ECR location that stores versions (tags) of a container image.
- Security Group: Virtual firewall rules controlling inbound and outbound network traffic.
- Service: ECS controller that keeps a desired number of tasks running.
- Subnet: Network segment inside a VPC where ECS tasks run.
- Task: One running instance of a task definition.
- Task Definition: ECS template describing image, CPU, memory, environment, and logging.
- VPC: Virtual Private Cloud, the private network boundary for AWS resources.

## AWS Console Access

This section assumes no AWS experience but you MUST have a valid account to access the AWS infrastructure.

1. Open a browser.
2. Go to https://console.aws.amazon.com
3. Sign in.

After sign-in, look at the top-right area of the page.

1. Confirm the username shown matches the user you just used to log in.
2. Click the same top-right account/username area.
3. Find and note the 12-digit AWS account number.

What you should see:

- Your login username.
- A 12-digit AWS account number.

If either looks wrong, stop and correct login/account before continuing.

Why this is needed later:

- Account number is needed for tasks such as building ECR image URLs and confirming you are deploying to the correct account.
- Username is a quick safety check that you are in the expected login context.
- Role details are useful for permission troubleshooting, but not required for initial discovery.

Near the top-right area, find the Region selector (for example, N. Virginia).

1. Click the Region selector.
2. Choose the region your team uses for this work (eg. `us-east-1`).

What you should see:

- The region name stays visible in the header after selection.

## Using CloudShell

1. Stay in AWS Console in your browser.
2. In the top header, click the CloudShell icon (terminal symbol).
3. Wait for the terminal panel to open.

What you should see:

- A shell prompt where you can type commands.

### Check ECR push/pull capability

This is the first meaningful check. If you cannot get an ECR auth token, you cannot push or pull container images regardless of anything else.

```bash
aws ecr get-authorization-token
```

- PASS: returns `authorizationData`. ECR push/pull workflows are accessible.
- FAIL: AccessDenied. You cannot push or pull images. Stop and request ECR permissions.

### Check Fargate capability

This one command tells you whether your identity is allowed to create and manage Fargate tasks.

```bash
MY_ARN=$(aws sts get-caller-identity --query Arn --output text) && \
aws iam simulate-principal-policy \
  --policy-source-arn "$MY_ARN" \
  --action-names \
    ecs:RunTask \
    ecs:StopTask \
    ecs:DescribeTasks \
    ecs:RegisterTaskDefinition \
    ecs:ExecuteCommand \
    iam:PassRole \
    logs:CreateLogGroup \
    logs:PutLogEvents \
  --resource-arns "*" \
  --query "EvaluationResults[*].[EvalActionName,EvalDecision]" \
  --output table
```

- PASS: every row shows `allowed`.
- FAIL: any row shows `implicitDeny` or `explicitDeny` for that specific action.

If this command itself returns AccessDenied:

- Your account blocks IAM policy simulation.
- Copy the full error message and send it to your AWS admin with a request to either run this check for you or confirm Fargate task permissions directly.

### Read failures simply

If a command fails, use this guide:

1. AccessDenied
    - Meaning: your login is valid, but you are missing permission.
2. Could not connect or endpoint errors
    - Meaning: region, network, or endpoint issue.
3. Any other FAIL
    - Meaning: capture the exact error text and send it to your AWS admin.

### Write down what you learned

Capture these sensitive items **in a secure document** before moving on:

1. Account number and region (from Section 1).
2. ECR auth token check: PASS or FAIL.
3. Fargate simulate results: which actions are allowed and which are denied.
4. Exact error text for anything that failed.

This is your permission baseline. Share denied actions with your AWS admin to unblock setup.
