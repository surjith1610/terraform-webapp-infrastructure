resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.webapp_sg.id]
  }

  tags = {
    Name = "database-security-group"
  }
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "postgres-db-parameter-group"
  family      = "postgres16"
  description = "Custom parameter group for PostgreSQL DB instance"

  tags = {
    Name = "postgres-db-parameter-group"
  }
}

resource "aws_db_subnet_group" "private_subnet_group" {
  name        = "private-subnet-group"
  description = "Private subnet group"
  subnet_ids  = aws_subnet.private_subnets[*].id

  tags = {
    Name = "private-subnet-group"
  }
}

resource "aws_db_instance" "csye6225_appdb" {
  identifier        = var.rds_identifier
  engine            = var.rds_engine
  instance_class    = var.rds_instance_type
  allocated_storage = var.rds_storage_size
  db_name           = var.db_name
  username          = var.db_username
  # password               = var.db_password
  password               = random_password.rds_password.result
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_subnet_group.name
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_key.arn

  tags = {
    Name = "csye6225-appdb"
  }
}
