# tf-aws-infra

## Overview

This repository contains **Terraform configuration files** to set up a robust AWS infrastructure. The setup includes:

1. A **Virtual Private Cloud (VPC)** with subnets, route tables, and an Internet Gateway distributed across multiple availability zones.  
2. **EC2 Instances** provisioned using a Launch Template, including custom AMIs built with **Packer** to preconfigure the application.  
3. An **RDS PostgreSQL database**, securely placed in a private subnet.  
4. **S3 Bucket** for storing application assets, profile pictures, and logs.  
5. **CloudWatch** integration for centralized application logging and performance metrics.  
6. **Route 53** for DNS hosting and domain management.  
7. **Auto Scaling Groups** and a **Load Balancer** to dynamically scale EC2 instances based on traffic load.  
8. **SNS and Lambda Functions** for user verification through email, using the **SendGrid API**.  
9. **CI/CD Pipeline** using **GitHub Actions**, including automated EC2 Launch Template refresh for seamless deployments.  
10. Fine-grained **IAM Roles and Policies** to enhance security.  
11. SSL/TLS Certificate import and setup for secure HTTPS communication.

## Key Features of This Setup

1. **Scalable Architecture**: Auto Scaling Groups and Load Balancer ensure high availability and fault tolerance.  
2. **Secure Infrastructure**: Resources are secured with fine-grained IAM roles, encryption using AWS KMS, and SSL/TLS for HTTPS communication.  
3. **CI/CD Integration**: GitHub Actions automate build, testing, and deployment processes, keeping the environment up to date.  
4. **Logging and Monitoring**: Centralized logging with CloudWatch ensures efficient debugging and system health monitoring.  
5. **DNS Management**: Route 53 simplifies domain management with hosted zones.  
6. **Serverless Email Verification**: Lambda functions and SNS streamline user verification with SendGrid integration.  

## Please check the Web application repository which will be deployed using this reusable Infrastructure code here:
https://github.com/surjith1610/cloud-webapplication
## Please check the serverless function repository for the user verification lambda function code here:
https://github.com/surjith1610/serverless-webapp-function

---

## Prerequisites

1. **Terraform** (version >= 1.0)  
2. **Add the zipped lambda function to the repo
3. **AWS CLI** with a configured profile for AWS credentials.  
   Export the profile to be used with Terraform:  
   ```bash
   export AWS_PROFILE="your_profile_name"

## Steps to be followed for resource provisioning
```bash
    terraform init
    terraform plan -var-file="variables.tfvars"
    terraform apply -var-file="variables.tfvars"
    terraform destroy -var-file="variables.tfvars"
```

## Steps for SSL certificate activation
```bash
    sudo openssl genrsa -out private.key 2048
    sudo openssl req -new -key private.key -out csr.pem
    cat csr.pem
    openssl rsa -in private.key -text > private_key.pem

    aws acm import-certificate \
    --certificate fileb://your_certificate.pem \
    --private-key fileb://private_key.pem \
    --certificate-chain fileb://your_certificate_chain.pem \
    --region us-east-1
