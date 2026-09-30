# OELS k6 Fargate Implementation Plan

## Overview

This plan creates the AWS infrastructure needed to run containerized load tests for the **OpenEdge Dev Suite** (OELS), a test suite owned by Progress OpenEdge.

OELS packages load tests as container images. The first image is `pug/k6`, which contains the Grafana k6 test framework and all OELS test scripts.Each image is versioned and stored in ECR under the `pug/` namespace.

### What Gets Created and Why

The following AWS resources are created as part of this plan. They are grouped by their role in the system.

#### Image Registry (ECR)

| Resource | Name | Purpose |
|---|---|---|
| ECR Repository | `pug/k6` | Stores all versioned builds of the k6 test image. One repository per image type. Future images (e.g. `pug/server`) each get their own repository under the same `pug/` namespace. |

#### Identity and Access (IAM)

| Resource | Name | Purpose |
|---|---|---|
| Task Execution Role | `pug-k6-execution-role` | Used by ECS itself to pull images from ECR and write logs to CloudWatch. Required by Fargate for every task. |
| Task Role | `pug-k6-task-role` | Used by the running container. Grants the minimum permissions the container needs at runtime, including ECS Exec access for interactive shells. |

#### Compute (ECS)

| Resource | Name | Purpose |
|---|---|---|
| ECS Cluster | `pug-k6-cluster` | Logical boundary for all OELS k6 tasks. All task runs are launched into this cluster. |
| Task Definition | `pug-k6` | Template that describes the container image, CPU/memory sizing, EFS mounts, logging, and ECS Exec configuration. Registers a new revision each time it is updated. |

#### Persistent Storage (EFS)

EFS provides shared filesystem mounts so that test configs, output logs, and HTML reports survive container restarts and are accessible across task runs.

| Resource | Name | Purpose |
|---|---|---|
| EFS Filesystem | `pug-k6-efs` | The shared filesystem. A single filesystem serves all OELS k6 tasks. |
| Mount Target | (per subnet) | Connects the EFS filesystem into the VPC subnet where ECS tasks run. One mount target per availability zone. |
| Access Point | `pug-k6-shared` or `pug-k6-<developer>` | Scopes access to a specific path inside EFS. One shared access point for team use, or one per developer for isolation. Each of the four container volume paths (`configs`, `docs`, `html`, `logs`) maps to an access point. |

#### Observability (CloudWatch)

| Resource | Name | Purpose |
|---|---|---|
| Log Group | `/ecs/pug-k6` | Receives stdout/stderr from every k6 task. Log streams are created automatically per task run. |

### Resource Hierarchy

```
AWS Account
└── Region (e.g. us-east-1)
    ├── ECR
    │   └── pug/k6             ← image repository (pug/server would be a sibling)
    ├── IAM
    │   ├── pug-k6-execution-role
    │   └── pug-k6-task-role
    ├── ECS
    │   └── pug-k6-cluster
    │       └── Task Definition: pug-k6
    │           └── Container: k6  (image from pug/k6 ECR repo)
    │               ├── Mount: /opt/k6/tests/configs  → EFS access point
    │               ├── Mount: /opt/k6/tests/docs     → EFS access point
    │               └── Mount: /opt/k6/tests/logs     → EFS access point
    ├── EFS
    │   └── pug-k6-efs
    │       ├── Mount Target (subnet)
    │       └── Access Points
    │           ├── pug-k6-shared  (or per-developer paths)
    │           └── ...
    └── CloudWatch Logs
        └── /ecs/pug-k6
            └── ecs/k6/<task-id>  ← one stream per task run
```

---

## Prerequisites

Access checks in [README.md](README.md) must be complete and confirmed as **allowed**.
Proceed with full implementation using:

- ECR for container image storage
- ECS Fargate for on-demand runtime
- EFS for persistent volume mounts (configs, docs, html, logs)
- CloudWatch Logs for task output
- ECS Exec for interactive shell access

---

## Phase A: Foundation

### A1 - Create ECR Repository

Run in CloudShell or local terminal:

```bash
aws ecr create-repository \
  --repository-name pug/k6 \
  --image-scanning-configuration scanOnPush=true \
  --image-tag-mutability IMMUTABLE
```

Save the `repositoryUri` from the output. It will look like:

```
<account-id>.dkr.ecr.<region>.amazonaws.com/pug/k6
```

### A2 - Create IAM Task Execution Role

This role allows ECS to pull images and write logs on your behalf.

```bash
aws iam create-role \
  --role-name pug-k6-execution-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name pug-k6-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### A3 - Create IAM Task Role

This role is assumed by the running container. It enables ECS Exec.

```bash
aws iam create-role \
  --role-name pug-k6-task-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam put-role-policy \
  --role-name pug-k6-task-role \
  --policy-name pug-k6-exec-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }]
  }'
```

### A4 - Create ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name pug-k6-cluster \
  --tags key=Project,value=pug key=Component,value=k6
```

### A5 - Create CloudWatch Log Group

```bash
aws logs create-log-group --log-group-name /ecs/pug-k6
```

---

## Phase B: EFS Persistent Storage

The k6 container exposes four volume mount points:

| Mount Path | Purpose |
|---|---|
| `/opt/k6/tests/configs` | Test configuration files (refreshed from samples at startup) |
| `/opt/k6/tests/docs` | Documentation files (refreshed from docs.local at startup) |
| `/opt/k6/tests/logs` | k6 test result logs and output |

### B1 - Create EFS Filesystem

```bash
aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode bursting \
  --tags Key=Name,Value=pug-k6-efs Key=Project,Value=pug
```

Save the `FileSystemId` from the output (format: `fs-xxxxxxxx`).

### B2 - Create Mount Target

Replace `<subnet-id>` and `<security-group-id>` with values from your VPC. Use the same subnet your ECS tasks will run in.

```bash
aws efs create-mount-target \
  --file-system-id <fs-id> \
  --subnet-id <subnet-id> \
  --security-groups <security-group-id>
```

Repeat for each availability zone subnet if you need HA.

### B3 - Create EFS Access Points (one per developer or shared)

Create a shared access point for team use:

```bash
aws efs create-access-point \
  --file-system-id <fs-id> \
  --root-directory "Path=/pug-k6,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755}" \
  --posix-user "Uid=1000,Gid=1000" \
  --tags Key=Name,Value=pug-k6-shared
```

For per-developer isolation, create one access point per developer with a unique root path:

```bash
aws efs create-access-point \
  --file-system-id <fs-id> \
  --root-directory "Path=/pug-k6/<developer-name>,CreationInfo={OwnerUid=1000,OwnerGid=1000,Permissions=755}" \
  --posix-user "Uid=1000,Gid=1000" \
  --tags Key=Name,Value=pug-k6-<developer-name>
```

Save the `AccessPointId` (format: `fsap-xxxxxxxx`) for each.

---

## Phase C: Image Build and Push

### C1 - Authenticate Docker to ECR

```bash
aws ecr get-login-password --region <region> | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.<region>.amazonaws.com
```

### C2 - Build the k6 Image

From the repository root (where `Dockerfile-k6` lives):

```bash
docker build \
  --build-arg BUILD_VERSION=<version> \
  -t pug/k6:<version> \
  -t pug/k6:latest \
  -f Dockerfile-k6 .
```

### C3 - Tag and Push to ECR

```bash
ECR_REPO=<account-id>.dkr.ecr.<region>.amazonaws.com/pug/k6

docker tag pug/k6:<version> ${ECR_REPO}:<version>
docker push ${ECR_REPO}:<version>
```

Do not push the `latest` tag to ECR. Use explicit version tags only.

---

## Phase D: Task Definition

### D1 - Register Task Definition

Save the JSON below as `task-def.json`. Replace all placeholder values before running.

```json
{
  "family": "pug-k6",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::<account-id>:role/pug-k6-execution-role",
  "taskRoleArn": "arn:aws:iam::<account-id>:role/pug-k6-task-role",
  "containerDefinitions": [
    {
      "name": "k6",
      "image": "<account-id>.dkr.ecr.<region>.amazonaws.com/pug/k6:<version>",
      "essential": true,
      "command": ["sh"],
      "linuxParameters": { "initProcessEnabled": true },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/pug-k6",
          "awslogs-region": "<region>",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "mountPoints": [
        { "sourceVolume": "configs", "containerPath": "/opt/k6/tests/configs" },
        { "sourceVolume": "docs",    "containerPath": "/opt/k6/tests/docs" },
        { "sourceVolume": "logs",    "containerPath": "/opt/k6/tests/logs" }
      ]
    }
  ],
  "volumes": [
    {
      "name": "configs",
      "efsVolumeConfiguration": {
        "fileSystemId": "<fs-id>",
        "authorizationConfig": { "accessPointId": "<fsap-configs>", "iam": "DISABLED" },
        "transitEncryption": "ENABLED"
      }
    },
    {
      "name": "docs",
      "efsVolumeConfiguration": {
        "fileSystemId": "<fs-id>",
        "authorizationConfig": { "accessPointId": "<fsap-docs>", "iam": "DISABLED" },
        "transitEncryption": "ENABLED"
      }
    },
    {
      "name": "logs",
      "efsVolumeConfiguration": {
        "fileSystemId": "<fs-id>",
        "authorizationConfig": { "accessPointId": "<fsap-logs>", "iam": "DISABLED" },
        "transitEncryption": "ENABLED"
      }
    }
  ]
}
```

Register it:

```bash
aws ecs register-task-definition --cli-input-json file://task-def.json
```

---

## Phase E: Running Tasks

### E1 - Start a Task

```bash
aws ecs run-task \
  --cluster pug-k6-cluster \
  --task-definition pug-k6 \
  --launch-type FARGATE \
  --enable-execute-command \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-id>],securityGroups=[<security-group-id>],assignPublicIp=ENABLED}" \
  --tags key=Owner,value=<developer-name> key=Project,value=pug
```

Save the `taskArn` from the output.

### E2 - Wait for Task to Reach RUNNING

```bash
aws ecs wait tasks-running \
  --cluster pug-k6-cluster \
  --tasks <task-arn>
```

### E3 - Open Interactive Shell (ECS Exec)

```bash
aws ecs execute-command \
  --cluster pug-k6-cluster \
  --task <task-arn> \
  --container k6 \
  --command "/bin/sh" \
  --interactive
```

You will land in `/opt/k6/tests` with EFS mounts active.

### E4 - Run a Test

Inside the shell:

```bash
k6 run launchUnifiedScenario.js
```

Results write to `/opt/k6/tests/logs` which is persisted on EFS.

### E5 - Stop Task When Done

```bash
aws ecs stop-task \
  --cluster pug-k6-cluster \
  --task <task-arn>
```

Fargate releases compute immediately. EFS data is retained.

---

## Phase F: Validation

### F1 - Confirm Task Started

```bash
aws ecs describe-tasks \
  --cluster pug-k6-cluster \
  --tasks <task-arn> \
  --query "tasks[0].lastStatus"
```

Expected: `"RUNNING"`

### F2 - Confirm CloudWatch Logs Are Flowing

```bash
aws logs get-log-events \
  --log-group-name /ecs/pug-k6 \
  --log-stream-name ecs/k6/<task-id> \
  --limit 20
```

### F3 - Confirm EFS Persistence

After stopping and restarting a task, open a shell and verify:

```bash
ls /opt/k6/tests/logs
ls /opt/k6/tests/configs
```

Files written by a prior task run must still be present.

### F4 - Confirm Developer Isolation

Each developer's task should use a separate EFS access point with its own root path. Confirm by checking that one developer's shell cannot see another developer's files under `/opt/k6/tests/logs`.

---

## Capacity Reference

| Workload | vCPU | Memory |
|---|---|---|
| Smoke (connectivity only) | 0.5 | 1 GB |
| Load (standard test run) | 1 | 2 GB |
| Stress (high VU count) | 2+ | 4+ GB |

Tuning rule:
- High CPU utilization: increase `cpu` in the task definition.
- OOM or swap pressure: increase `memory` in the task definition.

---

## Definition of Done

1. ECR repository exists with at least one pushed image version.
2. EFS filesystem exists with mount target in the task subnet.
3. EFS access points exist for each volume path (configs, docs, html, logs).
4. Task definition is registered with all four EFS volume mounts.
5. A Fargate task starts, reaches RUNNING, and accepts an ECS Exec shell.
6. A k6 test run completes and writes logs to the EFS `logs` mount.
7. Log output appears in CloudWatch under `/ecs/pug-k6`.
8. After task stop and restart, prior log files are still present on EFS.
9. Per-developer isolation is enforced via separate EFS access points or root paths.
