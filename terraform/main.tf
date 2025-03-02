terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile_name
}

# Creating a secruty group that will be applied to our EC2 instance
resource "aws_security_group" "postgres_sg" {
  name_prefix = "postgres-sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP address
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to trusted sources
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance
resource "aws_instance" "db_server" {
  ami           = var.ec2_ami
  instance_type = "t2.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.postgres_sg.id]

  lifecycle {
      ignore_changes = [ami]
    }

  tags = {
    Name = "PostgresDBServer"
  }

  # The below code will create and configure our database, user, and tables
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install postgresql
              sudo apt install -y postgresql
              psql --version # check to make sure it was installed
              
              sudo -u postgres createuser ${var.DB_USER_NAME}
              sudo -u postgres createdb ${var.DB_NAME}

              # Creating listening_history table
              sudo -u postgres psql -d ${var.DB_NAME} -c "CREATE TABLE listening_history (id SERIAL PRIMARY KEY, track_uri VARCHAR(255), track_name VARCHAR(255), artist_name VARCHAR(255), album_name VARCHAR(255), played_at TIMESTAMP UNIQUE, ms_played INT, popularity INT);"

              # Adding comments for listening_history table
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON TABLE listening_history IS 'Stores information about each track the user has listened to on Spotify, including playback details and track metadata. For more information, refer to: https://developer.spotify.com/documentation/web-api/reference/get-recently-played';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.id IS 'Unique identifier for each listening history record.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.track_uri IS 'The unique URI for the track, used as an identifier within Spotify. Example: “spotify:track:6rqhFgbbKwnb9MLmUQDhG6.”';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.track_name IS 'The name of the track.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.artist_name IS 'The name of the track''s main artist.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.album_name IS 'The name of the album the track is part of.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.played_at IS 'The date and time when the track was played; each timestamp is unique to avoid duplicates.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.ms_played IS 'The total milliseconds the track was played, representing playback duration.';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "COMMENT ON COLUMN listening_history.popularity IS 'The popularity of the track. The value will be between 0 and 100, with 100 being the most popular. The popularity is calculated by an algorithm based on the total number of plays the track has had and how recent those plays are.';"

              # Adding password to database user
              sudo -u postgres psql -c "ALTER USER ${var.DB_USER_NAME} WITH ENCRYPTED PASSWORD '${var.DB_USER_PASSWORD}';"
              sudo -u postgres psql -d ${var.DB_NAME} -c "GRANT ALL PRIVILEGES ON DATABASE ${var.DB_NAME} TO ${var.DB_USER_NAME};"

              # Making the created user the owner of the two tables
              sudo -u postgres psql -d ${var.DB_NAME} -c "ALTER TABLE listening_history OWNER TO ${var.DB_USER_NAME};"

              # Get the PostgreSQL version and store it in a variable
              PSQL_VERSION=$(psql --version | awk '{print $3}' | cut -d'.' -f1)

              # Dynamically update postgresql.conf to listen on all addresses
              sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$PSQL_VERSION/main/postgresql.conf
              
              # Dynamically update pg_hba.conf to allow connections from any IP
              PSQL_VERSION=$(psql --version | awk '{print $3}' | cut -d'.' -f1)
              echo 'host    ${var.DB_NAME}    ${var.DB_USER_NAME}    0.0.0.0/0    md5' | sudo tee -a /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf

              # Restart PostgreSQL to apply the changes
              sudo service postgresql restart
              EOF

}

# Getting secret id from existing secret
data "aws_secretsmanager_secret" "secrets" {
  arn = var.secret_arn
}

# Store Spotify credentials, our newly created EC2 instance's public IP, and database credentials in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
  secret_string = jsonencode({
    SPOTIFY_CLIENT_ID = var.SPOTIFY_CLIENT_ID,
    SPOTIFY_CLIENT_SECRET = var.SPOTIFY_CLIENT_SECRET,
    SPOTIFY_REFRESH_TOKEN = var.SPOTIFY_REFRESH_TOKEN,

    DB_NAME = var.DB_NAME,
    DB_USER_NAME     = var.DB_USER_NAME,
    DB_USER_PASSWORD = var.DB_USER_PASSWORD,

    HOST_IP    = aws_instance.db_server.public_ip
  })
  lifecycle {
    ignore_changes = [ secret_string ]
  }

}


# Installing package dependancies
resource "null_resource" "install_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r layer/requirements.txt -t layer/python/lib/python3.9/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}


#------------------
# Creating dependency layer
#------------------
# Zipping the lambda layer
data "archive_file" "layer_zip" {                                                                                                                                                                                   
  type        = "zip"                                                                                                                                                                                                
  source_dir  = "layer"                                                                                                                                                                                         
  output_path = "${path.module}/layer.zip"
  depends_on = [
    null_resource.install_layer_dependencies
  ]                                                                                                                                                                         
}  

# Creating layer for dependencies
resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "py3_9_dependencies"
  compatible_runtimes = ["python3.9"]
  filename = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
  depends_on = [ 
    data.archive_file.layer_zip
   ]
}

# Zipping the lambda function and its dependencies
data "archive_file" "function_zip" {                                                                                                                                                                                   
  type        = "zip"                                                                                                                                                                                                
  source_dir  = "function"                                                                                                                                                                                         
  output_path = "${path.module}/function.zip"                                                                                                                                                                         
}

# Create Lambda function
resource "aws_lambda_function" "lambda" {
  function_name = "SpotifyAggrFunction"
  runtime       = "python3.9"
  handler       = "main.lambda_handler"
  role          = aws_iam_role.lambda_exec.arn
  timeout       = 10
  memory_size   = 3008
  architectures    = ["x86_64"]
  filename = data.archive_file.function_zip.output_path
  source_code_hash = data.archive_file.function_zip.output_base64sha256
                                                                                                                                                       

  ephemeral_storage {
    size = 512  # Ephemeral storage size in MB
  }

  # Passing variables to the lambda function's environment. These will be used to fetch our credentials
  environment {
    variables = {
      aws_region = var.aws_region
      secret_name = data.aws_secretsmanager_secret.secrets.name
    }
  }

  layers = [
    aws_lambda_layer_version.lambda_layer.arn
  ]

  depends_on = [ 
    data.archive_file.function_zip,
    aws_lambda_layer_version.lambda_layer
   ]

}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}



# CloudWatch rule to trigger the Lambda function every hour
resource "aws_cloudwatch_event_rule" "every_hour" {
  name        = "EveryHourRule"
  schedule_expression = "rate(1 hour)"
}

# Permission to invoke Lambda by CloudWatch
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn
}


# Output your newly created EC2 instance's public IP. Used to ssh into your EC2 instance.
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.db_server.public_ip
}
