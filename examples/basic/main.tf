#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module.
#
# This example is self-contained and requires only `project_id`: it creates a
# network (with a security group) via the terraform-stackit-network module, then
# lets the compute module create a network interface on that network and boot a
# server attached to it.
#####################################################################################

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-compute-network"
  routed      = true
  ipv4_prefix = "10.10.100.0/24"
  ipv4_nameservers = [
    "1.0.0.1",
    "1.1.1.1",
    "8.8.8.8",
  ]

  create_security_group      = true
  security_group_description = "Allow inbound HTTPS, all egress"
  security_group_rules = [
    {
      direction  = "ingress"
      ether_type = "IPv4"
      ip_range   = "0.0.0.0/0"
      protocol   = { name = "tcp" }
      port_range = { min = 443, max = 443 }
    },
    {
      direction  = "egress"
      ether_type = "IPv4"
      ip_range   = "0.0.0.0/0"
      protocol   = { name = "tcp" }
    },
  ]

  labels = {
    managed_by = "terraform"
    example    = "basic"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "compute" {
  source = "../.."

  project_id        = var.project_id
  name              = "example-server"
  machine_type      = var.machine_type
  availability_zone = "eu01-1"

  boot_volume = {
    source_type = "image"
    source_id   = var.image_id
    size        = 8
  }

  create_key_pair = true
  public_key      = trimspace(tls_private_key.this.public_key_openssh)

  # Let the compute module create the NIC on the network above and attach it.
  network_interfaces = {
    primary = {
      network_id         = module.network.network_id
      name               = "example-server-nic"
      security_group_ids = [module.network.security_group_id]
    }
  }

  user_data = <<-EOT
    #cloud-config
    package_update: true
  EOT

  labels = {
    managed_by = "terraform"
    example    = "basic"
  }
}
