# ─── Core ─────────────────────────────────────────────────────────────────────

variable "project_id" {
  description = "STACKIT project ID in which the server and related resources are created."
  type        = string
}

variable "create_server" {
  description = "Whether to create the server and its attached resources (public IPs, volume attachments). Set to false to disable all resources in this module."
  type        = bool
  default     = true
}

variable "name" {
  description = "The name of the server. Also used to derive the default key pair name."
  type        = string
}

variable "region" {
  description = "The resource region. If not defined, the provider region is used."
  type        = string
  default     = null
}

variable "labels" {
  description = "Key-value string pairs to attach to the server and key pair."
  type        = map(string)
  default     = {}
}

# ─── Server ───────────────────────────────────────────────────────────────────

variable "machine_type" {
  description = "Name of the machine type (flavor) for the server, e.g. `g2i.1`. See STACKIT machine types documentation."
  type        = string
}

variable "availability_zone" {
  description = "The availability zone of the server, e.g. `eu01-1`."
  type        = string
  default     = null
}

variable "image_id" {
  description = "The image ID to be used for an ephemeral disk on the server. Prefer `boot_volume` for persistent boot disks."
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data passed via cloud-init to the server (e.g. `file(\"cloud-init.yaml\")` or an inline script)."
  type        = string
  default     = null
}

variable "desired_status" {
  description = "The desired status of the server. Possible values: `active`, `inactive`, `deallocated`."
  type        = string
  default     = null

  validation {
    condition     = var.desired_status == null || contains(["active", "inactive", "deallocated"], coalesce(var.desired_status, "active"))
    error_message = "desired_status must be one of: active, inactive, deallocated."
  }
}

variable "affinity_group" {
  description = "The affinity group ID the server is assigned to."
  type        = string
  default     = null
}

variable "boot_volume" {
  description = <<-EOT
    The boot volume configuration for the server.
      - `source_type` (required) : `image` or `volume`.
      - `source_id`   (required) : image ID (when source_type = image) or volume ID (when source_type = volume).
      - `size`                   : boot volume size in GB. Required when `source_type` is `image`.
      - `performance_class`      : performance class of the boot volume.
      - `delete_on_termination`  : delete the volume when the server is terminated. Only allowed when source_type = image.
  EOT
  type = object({
    source_type           = string
    source_id             = string
    size                  = optional(number)
    performance_class     = optional(string)
    delete_on_termination = optional(bool)
  })
  default = null

  validation {
    condition     = try(var.boot_volume.source_type, null) == null || contains(["image", "volume"], try(var.boot_volume.source_type, ""))
    error_message = "boot_volume.source_type must be either \"image\" or \"volume\"."
  }
}

variable "network_interface_ids" {
  description = "List of PRE-EXISTING network interface IDs to attach to the server. Combined with any interfaces created via `network_interfaces`."
  type        = list(string)
  default     = null
}

variable "network_interfaces" {
  description = <<-EOT
    Map of network interfaces to CREATE and attach to the server, keyed by a stable identifier.
    Each value:
      - `network_id`         (required) : network ID the interface is attached to.
      - `name`                          : interface name.
      - `security_group_ids`            : list of security group IDs to apply.
      - `allowed_addresses`             : list of CIDRs allowed on the interface.
      - `ipv4`                          : fixed IPv4 address.
      - `security`                      : set false to disable security groups on the interface.
  EOT
  type = map(object({
    network_id         = string
    name               = optional(string)
    security_group_ids = optional(list(string))
    allowed_addresses  = optional(list(string))
    ipv4               = optional(string)
    security           = optional(bool)
  }))
  default = {}
}

# ─── Key pair ─────────────────────────────────────────────────────────────────

variable "create_key_pair" {
  description = "Whether to create a key pair from `public_key`. If false, provide an existing key pair name via `keypair_name`."
  type        = bool
  default     = false
}

variable "public_key" {
  description = "The public SSH key to upload (e.g. `chomp(file(\"~/.ssh/id_ed25519.pub\"))`). Required when `create_key_pair` is true."
  type        = string
  default     = null
}

variable "key_pair_name" {
  description = "Name for the created key pair. Defaults to `<name>-key` when not set. Used only when `create_key_pair` is true."
  type        = string
  default     = null
}

variable "keypair_name" {
  description = "Name of an existing key pair to use for the server. Ignored when `create_key_pair` is true."
  type        = string
  default     = null
}

# ─── Public IPs ───────────────────────────────────────────────────────────────

variable "public_ips" {
  description = <<-EOT
    Map of public IPs to create, keyed by a stable identifier. Each value:
      - `network_interface_id` : network interface (or virtual IP) ID to associate the public IP with. Optional (leave unset to reserve a floating IP).
      - `labels`               : key-value labels for the public IP.
  EOT
  type = map(object({
    network_interface_id = optional(string)
    labels               = optional(map(string))
  }))
  default = {}
}

# ─── Volume attachments ───────────────────────────────────────────────────────

variable "attach_volume_ids" {
  description = "List of existing volume IDs to attach to the server (data volumes, in addition to the boot volume)."
  type        = list(string)
  default     = []
}
