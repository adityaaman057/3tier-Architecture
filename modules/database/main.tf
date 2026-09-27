resource "random_password" "password" { #A
  length           = 16
  special          = false
  override_special = "_%@/'\""
}

resource "aws_db_instance" "database" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "8.4.9"    # "5.7"
  instance_class         = "db.t3.micro"   # "db.t3.micro"
  identifier             = "${var.namespace}-db-instance"
  name                   = "pets"
  username               = "admin"
  password               = random_password.password.result
  db_subnet_group_name   = var.vpc.database_subnet_group #B
  vpc_security_group_ids = [var.sg.db] #B
  skip_final_snapshot    = true
}
