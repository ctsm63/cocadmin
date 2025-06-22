terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-west-3"
}

# Clef SSH
resource "aws_key_pair" "mysshkey" {
  key_name = "mykey"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwBR/I8llq9DgeDqSPgxZbAU9d7L4sj0LYRL1ZH6fHt"
}

# Security group
resource "aws_security_group" "authorise_http" {
  name        = "authorise_http"
  description = "Autorise le trafic HTTP et SSH entrant"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Instance EC2

resource "aws_instance" "app_server" {
  ami           = "ami-04ec97dc75ac850b1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.authorise_http.id ]
  key_name = aws_key_pair.mysshkey.key_name

  user_data = <<-EOF
            #!/bin/bash
            apt update
            apt install -y docker.io
            docker run -d -p 5000:5000 cocadmin/2048-mern
            EOF

  tags = {
    Name = "mon_instance"
  }
}


