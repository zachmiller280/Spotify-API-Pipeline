# AWS Infrastucture with Terraform

We'll use an infrastructure-as-code tool called `Terraform`. This will allow us to quickly setup (and destroy) our AWS resources using code. 

>Note that Terraform works with multiple cloud resources, not just AWS. 

To learn a bit more about Terraform, check out [this tutorial](https://learn.hashicorp.com/terraform?utm_source=terraform_io).



## **AWS Resources Created**

### **1. Security Group (`aws_security_group.postgres_sg`)**  
- Allows inbound access on:
  - **Port 22 (SSH)** from any IP (`0.0.0.0/0`) – should be restricted for security.
  - **Port 5432 (PostgreSQL)** from any IP (`0.0.0.0/0`) – should be restricted to trusted sources.
- Allows outbound traffic to any destination.

### **2. EC2 Instance (`aws_instance.db_server`)**  
- Uses the specified AMI.
- Runs a user-data script that:
  - Installs PostgreSQL.
  - Creates a database and user.
  - Sets up tables (`listening_history`, `track_features`) for storing Spotify data.
  - Modifies PostgreSQL configurations to allow external connections.
  - Grants necessary privileges to the database user.

### **3. AWS Secrets Manager (`aws_secretsmanager_secret_version.db_credentials_version`)**  
- Stores:
  - Spotify API credentials.
  - EC2 instance public IP.
  - PostgreSQL database credentials.

### **4. Lambda Function (`aws_lambda_function.lambda`)**  
- Triggered every **hour** using **CloudWatch Events**.

### **5. Lambda Layer (`aws_lambda_layer_version.lambda_layer`)**  
- Contains required Python dependencies.
- Built and zipped using `pip install` in a local `null_resource` execution.

### **6. IAM Role & Policy (`aws_iam_role.lambda_exec` & `aws_iam_role_policy.lambda_exec_policy`)**  
- Grants Lambda permissions to assume the execution role.
- Allows **Secrets Manager access** to retrieve credentials.

### **7. CloudWatch Event Rule (`aws_cloudwatch_event_rule.every_hour`)**  
- Schedules the Lambda function to run **every hour**.

### **8. CloudWatch Lambda Invocation Permission (`aws_lambda_permission.allow_cloudwatch`)**  
- Grants CloudWatch permission to trigger the Lambda function.


## Manual Setup: AWS Secrets Manager & EC2 Key Pair
Before deploying the Terraform configuration, you need to manually create two resources in the AWS Console:

### AWS Secrets Manager Secret
What is this? AWS Secrets store sensitive credentials (e.g., database passwords, API keys) securely. Terraform will modify this secret and it will also be by our Lambda function to access our database and Spotify's API.

How to create it:

1. Navigate to **AWS Secrets Manager**.
1. Click **Store a new secret** and choose **Other type of secret** as Secret type.
1. Do not enter any values—leave the secret data blank.
1. Choose a name (e.g., my-app-secrets) and save it.

>Note the `Secret ARN`; you'll need it for Terraform.

### EC2 Key Pair

What is this? The key pair allows you to securely SSH into the EC2 instance if needed (for troubleshooting or manual configurations).

How to create it:
1. Navigate to **EC2>Network and Security>Key Pairs>Create New Key Pair**
1. Choose a name (e.g., `my-ec2-keypair`) and note this down.
1. Set Key pair type = `RSA` and Private key file format = `.pem`
1. Click Create, and the private key (.pem file) will download automatically.

>Note: Store this file securely—you won’t be able to download it again.

## Setup

1. Install Terraform 

    You can find installation instructions [here](https://learn.hashicorp.com/tutorials/terraform/install-cli) for your OS.

1. Change into `terraform` directory

    ```bash
    cd ~\Spotify-API-Pipeline\terraform
    ```

1. Fill in the `default` parameters `variables.tf` file. 

    **Notes:** 
    * For added security, your `DB_USER_PASSWORD` should contain upper and lowercase letters, as well as numbers.
    * Make sure you choose the appropriate AMI as your `ec2_ami` may differ from mine (AMI's are different between regions).
      - For reference, my AMI name is `ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server`


1. May be a good idea to amend `.gitignore` to ignore all terraform files so you don't accidentally commit your password and other details. You'll need to remove the `!*.tf` line.

1. Making sure you are still in the terraform directory, run this command to download the AWS terraform plugin:

    ```bash
    terraform init
    ```

1. Run this command to create a plan based on `main.tf` and execute the planned changes to create resources in AWS:

    ```bash
    terraform plan
    
    terraform apply
    ```

1. (optional) Run this command to terminate the resources:

    ```
    terraform destroy
    ```


In the [AWS Console](https://aws.amazon.com/console/), you can view your newly created resources.

Also, by checking the logs of your newly created Lambda Function, we can see if the function is being executed successfully.  


### Table of Contents
0. [Project Overview](https://github.com/zachmiller280/Spotify-API-Pipeline/tree/main)
1. [Spotify API Configuration](1-spotify_api.md)
1. [AWS Account & AWS CLI Setup](2-aws.md)
1. [AWS Infrastructure with Terraform](3-aws_infrastructure.md)
1. [Dashboarding](4-google_looker.md)
1. [Insert Spotify Extended Listening History](5-spotify_extended_listening.md)
