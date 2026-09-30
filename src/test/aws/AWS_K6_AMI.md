# AWS k6 EC2 from AMI

This document covers launching a pre-configured k6 runner instance from the shared OELS AMI.
The AMI was originally built by following the full setup guide in [AWS_K6_SETUP.md](AWS_K6_SETUP.md),
which documents every OS-level step, kernel tuning, and software installation that produced it.

## Creating an Instance

1. Log into the AWS Console.
2. Look under EC2 for Images -> AMIs
3. Select the "Grafana-K6" image.
4. Click on "Launch instance from AMI"

## Required Tags

* name: OELS-K6-Runner
* team: a-team
* application: platform
* owner: oeeng-ateam@progress.com
* expiration: 2030-12-31

## Instance Type

* 1000 VUs: r7a.xlarge (AMD with 4 vCPU with 32 GB)
* 2000 VUs: r7a.2xlarge (AMD with 8 vCPU with 64 GB)

## Key Pair

* Select "loadteam"

## Network Settings

* VPC: Default VPC
* Subnet: Must choose Availability Zone us-east-1d
* Security Groups:
    * SSH from Anywhere
    * Outbound-Ping
    * Outbound-TCP
    * K6-Dashboard
