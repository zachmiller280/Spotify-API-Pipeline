# AWS Account & CLI


## Setup

1. Create a personal [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start). Follow instructions [here](https://aws.amazon.com/getting-started/guides/setup-environment/module-one/) and setup with the **free tier**.

2. Secure your account following these [steps](https://aws.amazon.com/getting-started/guides/setup-environment/module-two/). 

    Here we are setting up MFA for the root user. The root is a special account that has access to **everything** and therefore it is important we secure this. In production, you should only use the root account for tasks that can only be done with the root account. 

    Thus, I would recommend setting up another user with more limited permissions. 

    For reference, I am using an IAM Identity Center (SSO) user with Admin permissions, but you could likely use an even more restricted permission set.

3. Setup AWS CLI following this [guide](https://aws.amazon.com/getting-started/guides/setup-environment/module-three/). 

    This allows us to control AWS services from the command line interface. The goal by the end of this is you should have a folder in your home directory called `.aws` which contains a `credentials` file. It will look something like this:

    ```config
    [default]
    aws_access_key_id = XXXX
    aws_secret_access_key = XXXX
    ```

    Once AWS CLI is configured, we will be able to interact with AWS services from the command line. This allows us to execute our Terraform code without exposing access keys.