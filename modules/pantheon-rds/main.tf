resource "aws_security_group" "main" {
  name   = "${var.name}-rds"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds"
  }
}

resource "aws_security_group_rule" "main" {
  count = length(var.source_security_group_id)

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = var.source_security_group_id[count.index]
  security_group_id        = aws_security_group.main.id
}

resource "aws_db_instance" "main" {
  allocated_storage          = var.allocated_storage
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  availability_zone          = var.availability_zone
  backup_retention_period    = var.backup_retention_period
  copy_tags_to_snapshot      = var.copy_tags_to_snapshot
  db_subnet_group_name       = var.db_subnet_group_name
  deletion_protection        = var.deletion_protection
  engine                     = var.engine
  engine_version             = var.engine_version
  identifier                 = var.name
  instance_class             = var.instance_class
  license_model              = var.license_model
  max_allocated_storage      = var.max_allocated_storage
  password                   = var.password
  skip_final_snapshot        = var.skip_final_snapshot
  storage_encrypted          = var.storage_encrypted
  storage_type               = var.storage_type
  username                   = var.username
  vpc_security_group_ids     = [aws_security_group.main.id]

  tags = {
    Name = var.name
  }
}
