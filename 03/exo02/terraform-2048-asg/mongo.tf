resource "aws_docdb_cluster" "mydb" {
  cluster_identifier = "mydb"
  master_username = "username"
  master_password = "password"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.docdb.id]
}

# DocumentDB Cluster Instances (Nodes)
resource "aws_docdb_cluster_instance" "docdb_instance" {
  count              = 1
  identifier         = "docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.mydb.id
  instance_class     = "db.t3.medium"
  apply_immediately  = true
}

