#####################################################################################
# "update" example — self-contained, requires only `project_id`.
#
# Builds a network + server (as in the basic example) and additionally enables the
# server update (OS patch) service.
#####################################################################################

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-compute-update-network"
  routed      = true
  ipv4_prefix = "10.10.102.0/24"
  ipv4_nameservers = [
    "1.0.0.1",
    "1.1.1.1",
    "8.8.8.8",
  ]

  create_security_group      = true
  security_group_description = "Allow all egress"
  security_group_rules = [
    {
      direction  = "egress"
      ether_type = "IPv4"
      ip_range   = "0.0.0.0/0"
      protocol   = { name = "tcp" }
    },
  ]

  labels = {
    managed_by = "terraform"
    example    = "update"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "compute" {
  source = "../.."

  project_id        = var.project_id
  name              = "example-update-server"
  machine_type      = var.machine_type
  availability_zone = "eu01-1"

  boot_volume = {
    source_type = "image"
    source_id   = var.image_id
    size        = 8
  }

  create_key_pair = true
  public_key      = trimspace(tls_private_key.this.public_key_openssh)

  network_interfaces = {
    primary = {
      network_id         = module.network.network_id
      name               = "example-update-server-nic"
      security_group_ids = [module.network.security_group_id]
    }
  }

  # Enable the server OS update service.
  enable_update = true

  labels = {
    managed_by = "terraform"
    example    = "update"
  }
}
