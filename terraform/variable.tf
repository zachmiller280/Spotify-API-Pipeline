## Spotify API credentials - Obtained through https://developer.spotify.com/documentation/web-api
# You can define your spotify credentials here or alter them within the Consoles's Secrets Manager 

variable "SPOTIFY_CLIENT_ID" {
  description = "Spotify application client ID - OPTIONAL FOR INITIAL SETUP"
  type        = string
  default     = "your_client_id" 
}

variable "SPOTIFY_CLIENT_SECRET" {
  description = "Spotify application client secret - OPTIONAL FOR INITIAL SETUP"
  type        = string
  default     = "your_client_secret"
}

variable "SPOTIFY_REFRESH_TOKEN" {
  description = "Spotify application refresh token - OPTIONAL FOR INITIAL SETUP"
  type        = string
  default     = "your_refresh_token"
}


## PostgreSQL database credentials

variable "DB_NAME" {
  description = "Database name"
  type        = string
  default     = "your_db_name"
}

variable "DB_USER_NAME" {
  description = "Database user's name"
  type        = string
  default     = "your_db_username"
}

variable "DB_USER_PASSWORD" {
  description = "Database user's password"
  type        = string
  sensitive   = true
  default     = "your_super_secret_password"
}


## AWS Credentials - Associated with your profile

# Your profile's region
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1" # UPDATE TO YOUR REGION
}


# SSO profile name. Run "aws configure sso" to confirm the profile is active.
variable "aws_profile_name" {
  description = "AWS profile name (SSO) - Set during `aws configure sso`"
  type        = string
  default     = "your_sso_profile"
}

# Identifies the EC2 instance to create. Use the appropriate AMI for your needs, region, etc. 
variable "ec2_ami" {
  description = "AMI for EC2"
  type        = string
  default     = "ami-04a81a99f5ec58529"  # UPDATED TO THE APPROPRIATE AMI FOR YOUR REGION
}

# YOU MUST CREATE THIS SECRET FROM THE CONSOLE - This will allow the Terraform to populate your credentials and pass the secret to the Lambda function
variable "secret_arn" {
  description = "ARN of the secret you created from the console"
  type        = string
  default     = "your_secret_arn"
}

# YOU MUST CREATE THIS SECRET FROM THE CONSOLE - Name of the your EC2 instance's key pair
variable "key_name" {
  description = "Name of the key pair you created from the console"
  type        = string
  default     = "your_key_pair_name"
}