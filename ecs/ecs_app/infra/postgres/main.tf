provider "aws" {
  region = var.region
}

provider "random" {}

resource "random_password" "postgres_master_pass" {
  length = 64
  special = false
  keepers = {
    master_user_name = var.master_username
  }
}

resource "aws_db_subnet_group" "private_subnets" {
  subnet_ids = var.db_subnets
}

resource "aws_security_group" "db_security_group" {
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    protocol = "tcp"
    to_port = 5432
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    protocol = "tcp"
    to_port = 5432
  }
}

resource "aws_db_instance" "postgresql_instance" {
  instance_class = "db.t2.micro"
  engine = "postgres"
  engine_version = "12.3"
  publicly_accessible = false
  allocated_storage = 20
  username = random_password.postgres_master_pass.keepers.master_user_name
  password = random_password.postgres_master_pass.result
  storage_type = "gp2"
  db_subnet_group_name = aws_db_subnet_group.private_subnets.name
  name = "appdb"
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  skip_final_snapshot = true
}

resource "aws_ssm_parameter" "postgres_url_parameter" {
  name = "/psql/url"
  type = "String"
  value = aws_db_instance.postgresql_instance.address
}

resource "aws_ssm_parameter" "postgres_master_password" {
  depends_on = [aws_db_instance.postgresql_instance]
  name = "postgres_master_password"
  type = "SecureString"
  value = random_password.postgres_master_pass.result
}