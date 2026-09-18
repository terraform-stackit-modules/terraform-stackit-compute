#####################################################################################
# "backup" example — self-contained, requires only `project_id`.
#
# Builds a network + server (as in the basic example) and additionally enables the
# server backup service and creates a daily backup schedule.
#####################################################################################

module "network" {
  source  = "terraform-stackit-modules/network/stackit"
  version = ">= 1.0.0"

  project_id  = var.project_id
  name        = "example-compute-backup-network"
  routed      = true
  ipv4_prefix = "10.10.101.0/24"
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
    example    = "backup"
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "compute" {
  source = "../.."

  project_id        = var.project_id
  name              = "example-backup-server"
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
      name               = "example-backup-server-nic"
      security_group_ids = [module.network.security_group_id]
    }
  }

  # Enable the backup service and schedule a daily backup with 14-day retention.
  enable_backup = true

  backup_schedules = {
    daily = {
      name             = "example-daily-backup"
      rrule            = "DTSTART;TZID=Europe/Berlin:20200803T023000 RRULE:FREQ=DAILY;INTERVAL=1"
      enabled          = true
      backup_name      = "example-daily"
      retention_period = 14
    }
  }

  labels = {
    managed_by = "terraform"
    example    = "backup"
  }
}
