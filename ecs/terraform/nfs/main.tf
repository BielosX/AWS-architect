resource "aws_efs_file_system" "docker_volumes_fs" {
  creation_token = "docker-volumes-fs"
}

resource "aws_efs_mount_target" "mount_targets" {
  count = length(var.availability_zones)
  file_system_id = aws_efs_file_system.docker_volumes_fs.id
  subnet_id = var.private_subnets[count.index]
}