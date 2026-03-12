resource "aws_security_group" "eice" {
  name        = "eice"
  description = "EC2 instance connect"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "EC2 instance connect"
  }
}

resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.eice.id]
}
