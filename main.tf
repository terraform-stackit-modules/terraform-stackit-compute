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
