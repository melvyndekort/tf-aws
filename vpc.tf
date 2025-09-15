data "aws_region" "current" {}

locals {
  name       = "generic"
  cidr_block = "172.16.0.0/16"
  region     = data.aws_region.current.id
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = local.cidr_block

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["172.16.101.0/24", "172.16.102.0/24", "172.16.103.0/24"]
  public_subnets  = ["172.16.111.0/24", "172.16.112.0/24", "172.16.113.0/24"]

  private_subnet_tags = {
    Tier = "Private"
  }

  public_subnet_tags = {
    Tier = "Public"
  }

  create_database_subnet_group = false

  create_igw             = true
  create_egress_only_igw = false

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  enable_vpn_gateway = false

  map_public_ip_on_launch = true

  enable_ipv6                                   = true
  public_subnet_assign_ipv6_address_on_creation = true

  private_subnet_enable_dns64 = false
  public_subnet_enable_dns64  = false

  private_subnet_ipv6_prefixes = [101, 102, 103]
  public_subnet_ipv6_prefixes  = [111, 112, 113]

  enable_flow_log = false
}
