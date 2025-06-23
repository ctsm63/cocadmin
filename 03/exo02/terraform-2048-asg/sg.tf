# Security Group pour les instances EC2
resource "aws_security_group" "app_server" {
  name        = "app_2048"
  description = "Authoriser le traffic sur port 5000 depuis le LB"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [ aws_security_group.alb.id ] # Fait référence au groupe de sécurité de notre Load Balancer
  }

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
    cidr_blocks = ["0.0.0.0/0"]  # Authoriser le ssh depuis partout
  }
  
  # Authoriser le traffic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group pour le load balancer
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for ALB"

  ingress {
    from_port   = 80
    to_port     = 80
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

# DocumentDB (Mongodb)
resource "aws_security_group" "docdb" {
  name        = "docdb-sg"
  description = "Security group for DocumentDB"

  # Autoriser le traffic de nos instances EC2
  ingress {
    from_port   = 27017 # Port MongoDB par défaut
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.app_server.id] # Fait référence au groupe de sécurité de nos instances EC2
  }

  # Authoriser le traffic sortant (optionel)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

