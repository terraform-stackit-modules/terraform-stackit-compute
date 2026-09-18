resource "stackit_key_pair" "this" {
  count = var.create_key_pair ? 1 : 0

  name       = coalesce(var.key_pair_name, "${var.name}-key")
  public_key = var.public_key
  labels     = var.labels
}

resource "stackit_network_interface" "this" {
  for_each = var.create_server ? var.network_interfaces : {}

  project_id         = var.project_id
  region             = var.region
  network_id         = each.value.network_id
  name               = each.value.name
  security_group_ids = each.value.security_group_ids
  allowed_addresses  = each.value.allowed_addresses
  ipv4               = each.value.ipv4
  security           = each.value.security
  labels             = var.labels
}

resource "stackit_server" "this" {
  count = var.create_server ? 1 : 0

  project_id        = var.project_id
  region            = var.region
  name              = var.name
  machine_type      = var.machine_type
  availability_zone = var.availability_zone
  image_id          = var.image_id
  keypair_name      = var.create_key_pair ? stackit_key_pair.this[0].name : var.keypair_name
  user_data         = var.user_data
  desired_status    = var.desired_status
  affinity_group    = var.affinity_group
  labels            = var.labels

  boot_volume = var.boot_volume

  agent = var.agent

  # Attach NICs created by this module (var.network_interfaces) plus any
  # pre-existing interface IDs passed in via var.network_interface_ids.
  network_interfaces = concat(
    [for k in sort(keys(var.network_interfaces)) : stackit_network_interface.this[k].network_interface_id],
    var.network_interface_ids != null ? var.network_interface_ids : []
  )
}

resource "stackit_public_ip" "this" {
  for_each = var.create_server ? var.public_ips : {}

  project_id           = var.project_id
  region               = var.region
  network_interface_id = each.value.network_interface_id
  labels               = each.value.labels
}

resource "stackit_server_volume_attach" "this" {
  for_each = var.create_server ? toset(var.attach_volume_ids) : toset([])

  project_id = var.project_id
  region     = var.region
  server_id  = stackit_server.this[0].server_id
  volume_id  = each.value
}

# ─── Backup ───────────────────────────────────────────────────────────────────

resource "stackit_server_backup_enable" "this" {
  count = var.create_server && var.enable_backup ? 1 : 0

  project_id       = var.project_id
  region           = var.region
  server_id        = stackit_server.this[0].server_id
  backup_policy_id = var.backup_policy_id
}

resource "stackit_server_backup_schedule" "this" {
  for_each = var.create_server && var.enable_backup ? var.backup_schedules : {}

  project_id = var.project_id
  region     = var.region
  server_id  = stackit_server.this[0].server_id
  name       = each.value.name
  rrule      = each.value.rrule
  enabled    = each.value.enabled

  backup_properties = {
    name             = each.value.backup_name
    retention_period = each.value.retention_period
    volume_ids       = each.value.volume_ids
  }

  depends_on = [stackit_server_backup_enable.this]
}

# ─── Update ───────────────────────────────────────────────────────────────────

resource "stackit_server_update_enable" "this" {
  count = var.create_server && var.enable_update ? 1 : 0

  project_id       = var.project_id
  region           = var.region
  server_id        = stackit_server.this[0].server_id
  update_policy_id = var.update_policy_id
}

# ─── Service account attachments ──────────────────────────────────────────────

resource "stackit_server_service_account_attach" "this" {
  for_each = var.create_server ? var.service_accounts : {}

  project_id            = var.project_id
  region                = var.region
  server_id             = stackit_server.this[0].server_id
  service_account_email = each.value
}
