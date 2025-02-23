# AWS Infrastucture

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



## **Security Considerations**
- **SSH (22) and PostgreSQL (5432) should be restricted** to trusted IPs.
- **Secrets Manager should have more restrictive IAM permissions** rather than allowing access to all secrets.


## Setup

1. Install Terraform 

    You can find installation instructions [here](https://learn.hashicorp.com/tutorials/terraform/install-cli) for your OS.

1. Change into `terraform` directory

    ```bash
    cd ~\Spotify-API-Pipeline\terraform
    ```

1. Open the `variables.tf` file

1. Fill in the `default` parameters.

    * Specify a master DB user password for your database. Note that this may show up in logs and the terraform state file. For added security, your password should contain upper and lowercase letters, as well as numbers.


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


In the [AWS Console](https://aws.amazon.com/console/), you can now view your Redshift cluster, IAM Role, and S3 Bucket. You can also manually delete or customize them here and query any Redshift databases using the query editor. Just be sure to specify the correct region in the top right hand side of the AWS console when looking for your Redshift cluster.


