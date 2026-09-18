#####################################################################################
# "service-account-attach" example — self-contained, requires only `project_id`.
#
# Builds a network + server (as in the basic example), creates a service account in
# the project and attaches it to the server.
#####################################################################################

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-compute-sa-network"
  routed      = true
  ipv4_prefix = "10.10.103.0/24"
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
    example    = "service-account-attach"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "stackit_service_account" "ci" {
  project_id = var.project_id
  name       = "example-ci-sa"
}

module "compute" {
  source = "../.."

  project_id        = var.project_id
  name              = "example-sa-server"
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
      name               = "example-sa-server-nic"
      security_group_ids = [module.network.security_group_id]
    }
  }

  # Attach the service account created above. The map key is a STABLE identifier
  # (known at plan time); the value is the service account email (known after
  # apply). This is why the module keys attachments by a static key, not by email.
  service_accounts = {
    ci = stackit_service_account.ci.email
  }

  labels = {
    managed_by = "terraform"
    example    = "service-account-attach"
  }
}
