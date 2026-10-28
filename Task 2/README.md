# Terraform "Create VPC, Subnets, Servers and Load Balancer" example

This folder contains a Terraform example that creates a VPC with two subnets, deploys a server in each subnet, attaches an Internet Gateway and public route table, and places both EC2 instances behind an Application Load Balancer.

## What this example creates

1. Create a VPC
2. Create 2 subnets named `SUBNET-A` and `SUBNET-B`
3. Create one server in each subnet
4. Add an Internet Gateway (IGW)
5. Add route tables and associate them with the subnets
6. Create and attach an Application Load Balancer to the EC2 instances
7. Add `prevent_destroy` and `ignore_changes` lifecycle rules
8. Print the ELB DNS name in the output

## Requirements

* You must have [Terraform](https://www.terraform.io/) installed on your computer.
* You must have an [AWS (Amazon Web Services)](http://aws.amazon.com/) account.
* Configure AWS access credentials before running Terraform.
* This example is designed for the AWS provider and AWS resources in the `ap-south-1` region.

## Configure AWS credentials

Set your AWS access keys in one of the supported ways.

### Option 1: AWS credentials file

On Linux, macOS, or Unix:

```bash
~/.aws/credentials
```

On Windows:

```bash
C:\Users\USERNAME\.aws\credentials
```

Example content:

```bash
[default]
aws_access_key_id = <your_access_key_id>
aws_secret_access_key = <your_secret_access_key>
```

### Option 2: Environment variables

Linux, macOS, or Unix:

```bash
export AWS_ACCESS_KEY_ID=<your_access_key_id>
export AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
```

Windows:

```bash
set AWS_ACCESS_KEY_ID=<your_access_key_id>
set AWS_SECRET_ACCESS_KEY=<your_secret_access_key>
```

## Using the code

* Initialize the working directory.

  ```bash
  terraform init
  ```

* Review the planned changes.

  ```bash
  terraform plan
  ```

* Deploy the infrastructure.

  ```bash
  terraform apply
  ```

* Check the output.

  After the apply completes, Terraform prints the ELB DNS name. You can copy that value and open it in a browser to test the application.

  Example output:

  ```bash
  elb_dns_name = "app-load-balancer-1234567890.ap-south-1.elb.amazonaws.com"
  ```

  Open the URL in a browser:

  ```bash
  http://app-load-balancer-1234567890.ap-south-1.elb.amazonaws.com
  ```

* Clean up the resources.

  ```bash
  terraform destroy
  ```

## Notes

* `prevent_destroy` is used to protect important resources such as the EC2 instances and load balancer from accidental deletion.
* `ignore_changes` is used to avoid Terraform drift from updating specific resource attributes after creation.
* The load balancer forwards traffic to both EC2 instances in the two subnets.
* The VPC uses a public route table and Internet Gateway so the EC2 instances and ALB can be reached from the internet.

