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

resource "aws_key_pair" "mysshkey" {
  key_name = "mykey"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcQDG0+BY2ekk8xbXoQQOQmcTP2k6ncwsxCRxPJ0b03"
}

data "aws_vpc" "my_vpc" {
  default = true
}


data "aws_subnets" "my_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
}

# Permet de récupérer facilement (avec `terraform output`, apres le apply) le nom de domaine du Load Balancer pour tester l'infra
output "alb_endpoint" {
  value = aws_lb.app_lb.dns_name
}


