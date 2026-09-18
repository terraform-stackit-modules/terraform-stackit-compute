<!-- BEGIN_TF_DOCS -->
# Terraform STACKIT Compute module

Terraform module which provisions a [STACKIT server (VM)](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server) and its directly-attached resources on [STACKIT](https://www.stackit.de/en/): SSH key pair, network interfaces, public IPs, data-volume attachments, the STACKIT Server Agent, the server backup service (enable + schedules), the server update (OS patch) service, and service-account attachments.

This repository is not from the official STACKIT organization.

## Usage

```hcl
module "compute" {
  source  = "terraform-stackit-modules/compute/stackit"
  version = ">= 1.0.0"

  project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  name              = "app-server"
  machine_type      = "g1a.1d"
  availability_zone = "eu01-1"

  boot_volume = {
    source_type = "image"
    source_id   = "012d2f5b-ee00-4700-9bea-cdabf0e1bfa8" # an Ubuntu image ID
    size        = 8
  }

  create_key_pair = true
  public_key      = file("~/.ssh/id_ed25519.pub")

  # Create a network interface on an existing network and attach it to the server.
  network_interfaces = {
    primary = {
      network_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      name               = "app-server-nic"
      security_group_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
    }
  }

  user_data = <<-EOT
    #cloud-config
    package_update: true
  EOT
}
```

See [`examples/basic`](./examples/basic) for a self-contained example that stands up a network
(via the `terraform-stackit-network` module) and a security group, then boots a server on it.

## Additional features

The module also wires the server's lifecycle add-ons. Each is off by default and self-contained:

### Server backup

Enable the backup service and create one or more backup schedules. A schedule requires the
service to be enabled first — the module handles the `depends_on` for you.

```hcl
enable_backup = true

backup_schedules = {
  daily = {
    name             = "app-daily-backup"
    rrule            = "DTSTART;TZID=Europe/Berlin:20200803T023000 RRULE:FREQ=DAILY;INTERVAL=1"
    enabled          = true
    backup_name      = "app-daily"
    retention_period = 14
    # volume_ids     = null  # null = all volumes
  }
}
```

See [`examples/backup`](./examples/backup) for a self-contained, Terratest-covered example.

### Server update (OS patch service)

```hcl
enable_update = true
# update_policy_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # optional
```

See [`examples/update`](./examples/update) for a self-contained, Terratest-covered example.

### Service-account attachments

Attach one or more service accounts to the server. Keyed by a **stable identifier**, not the
email — the value is the email. This avoids a `for_each` over a value that is only known after
apply (e.g. a service account created in the same run).

```hcl
service_accounts = {
  ci = stackit_service_account.ci.email
}
```

See [`examples/service-account-attach`](./examples/service-account-attach) for a self-contained,
Terratest-covered example that creates a service account and attaches it.

### STACKIT Server Agent

```hcl
agent = {
  provisioning_policy = "INHERIT" # ALWAYS | NEVER | INHERIT
}
```

## Composition

- Provide your own key pair with `terraform-stackit-key-pair` and pass its name via
  `keypair_name`, **or** let this module create one with `create_key_pair = true` + `public_key`.
- The module can create network interfaces for you (`network_interfaces`) and/or attach
  pre-existing ones (`network_interface_ids`); the server attaches the union of both.

## Notes

- `boot_volume.size` is required when `source_type = "image"`.
- A server effectively needs at least one network interface to be reachable — provide one via
  `network_interfaces` (created here) or `network_interface_ids` (existing).
- Only the **public** SSH key is an input — never commit a private key.
- **Benign provider warning.** During `apply` the STACKIT provider may print
  `Warning: No network interfaces configured` on the server resource, even when interfaces
  are attached. This is a known artifact of the provider: `network_interfaces` on
  `stackit_server` is still marked optional pending a migration path, so the check fires
  although the interface is in fact attached (the created NIC is wired to the server). It is
  safe to ignore — the server comes up with its interface.
- **Backup schedules require `enable_backup = true`.** The module gates the schedules on the
  backup-enable resource (`depends_on`); only one enable resource per server is allowed.
- **`service_accounts` is keyed by a stable identifier, not the email.** The map value is the
  email. Using a static key keeps `for_each` off a known-after-apply value.
- The Terratest examples `backup`, `update` and `service-account-attach` each provision a **real
  server** (and `service-account-attach` also a real `stackit_service_account`); a full
  `go test ./...` run therefore stands up several servers. Target one with
  `go test -run TestExamplesBackup ./...` to validate them individually.

<!-- markdownlint-disable MD001 -->
### Contributing

This module follows the conventions of the `terraform-stackit-modules` organization. Before opening a PR:

1. [Install pre-commit](https://pre-commit.com/#install) and run `pre-commit install`.
2. Install the required tools: [tflint](https://github.com/terraform-linters/tflint), [tfsec](https://aquasecurity.github.io/tfsec/), [terraform-docs](https://github.com/terraform-docs/terraform-docs), [golang](https://go.dev/doc/install), [coreutils](https://www.gnu.org/software/coreutils/).
3. Run the checks: `pre-commit run -a`.

**Do not manually edit `README.md`** — it is generated by `terraform-docs` from this file and the module's inputs/outputs.

## Terratest

The `test/` directory holds a Terratest integration test that applies the `examples/basic` root module against a real STACKIT project (requires `STACKIT_SERVICE_ACCOUNT_KEY` and `STACKIT_PROJECT_ID`).

```bash
cd test
go mod init github.com/terraform-stackit-modules/terraform-stackit-compute
go get github.com/gruntwork-io/terratest@v1.0.1
go mod tidy
go test -v -timeout 45m ./...
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_stackit"></a> [stackit](#requirement\_stackit) | >= 0.113.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_stackit"></a> [stackit](#provider\_stackit) | >= 0.113.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [stackit_key_pair.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/key_pair) | resource |
| [stackit_network_interface.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/network_interface) | resource |
| [stackit_public_ip.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/public_ip) | resource |
| [stackit_server.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server) | resource |
| [stackit_server_backup_enable.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server_backup_enable) | resource |
| [stackit_server_backup_schedule.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server_backup_schedule) | resource |
| [stackit_server_service_account_attach.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server_service_account_attach) | resource |
| [stackit_server_update_enable.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server_update_enable) | resource |
| [stackit_server_volume_attach.this](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server_volume_attach) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Name of the machine type (flavor) for the server, e.g. `g2i.1`. See STACKIT machine types documentation. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the server. Also used to derive the default key pair name. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | STACKIT project ID in which the server and related resources are created. | `string` | n/a | yes |
| <a name="input_affinity_group"></a> [affinity\_group](#input\_affinity\_group) | The affinity group ID the server is assigned to. | `string` | `null` | no |
| <a name="input_agent"></a> [agent](#input\_agent) | Optional STACKIT Server Agent configuration.<br/>  - `provisioning_policy` : `ALWAYS`, `NEVER`, or `INHERIT` (INHERIT follows the image default). | <pre>object({<br/>    provisioning_policy = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_attach_volume_ids"></a> [attach\_volume\_ids](#input\_attach\_volume\_ids) | List of existing volume IDs to attach to the server (data volumes, in addition to the boot volume). | `list(string)` | `[]` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The availability zone of the server, e.g. `eu01-1`. | `string` | `null` | no |
| <a name="input_backup_policy_id"></a> [backup\_policy\_id](#input\_backup\_policy\_id) | Optional backup policy ID for the server backup service. | `string` | `null` | no |
| <a name="input_backup_schedules"></a> [backup\_schedules](#input\_backup\_schedules) | Map of server backup schedules to create, keyed by a stable identifier. Requires `enable_backup = true`.<br/>Each value:<br/>  - `name`             : the schedule name.<br/>  - `rrule`            : an RFC 5545 recurrence rule, e.g. "DTSTART;TZID=Europe/Berlin:20200803T023000 RRULE:FREQ=DAILY;INTERVAL=1".<br/>  - `enabled`          : whether the schedule is enabled (default true).<br/>  - `backup_name`      : name given to the backups produced by this schedule.<br/>  - `retention_period` : retention period in days.<br/>  - `volume_ids`       : optional list of volume IDs to back up (null = all). | <pre>map(object({<br/>    name             = string<br/>    rrule            = string<br/>    enabled          = optional(bool, true)<br/>    backup_name      = string<br/>    retention_period = number<br/>    volume_ids       = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_boot_volume"></a> [boot\_volume](#input\_boot\_volume) | The boot volume configuration for the server.<br/>  - `source_type` (required) : `image` or `volume`.<br/>  - `source_id`   (required) : image ID (when source\_type = image) or volume ID (when source\_type = volume).<br/>  - `size`                   : boot volume size in GB. Required when `source_type` is `image`.<br/>  - `performance_class`      : performance class of the boot volume.<br/>  - `delete_on_termination`  : delete the volume when the server is terminated. Only allowed when source\_type = image. | <pre>object({<br/>    source_type           = string<br/>    source_id             = string<br/>    size                  = optional(number)<br/>    performance_class     = optional(string)<br/>    delete_on_termination = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_create_key_pair"></a> [create\_key\_pair](#input\_create\_key\_pair) | Whether to create a key pair from `public_key`. If false, provide an existing key pair name via `keypair_name`. | `bool` | `false` | no |
| <a name="input_create_server"></a> [create\_server](#input\_create\_server) | Whether to create the server and its attached resources (public IPs, volume attachments). Set to false to disable all resources in this module. | `bool` | `true` | no |
| <a name="input_desired_status"></a> [desired\_status](#input\_desired\_status) | The desired status of the server. Possible values: `active`, `inactive`, `deallocated`. | `string` | `null` | no |
| <a name="input_enable_backup"></a> [enable\_backup](#input\_enable\_backup) | Whether to enable the server backup service (stackit\_server\_backup\_enable). Required before creating backup schedules. Only one enable resource per server. | `bool` | `false` | no |
| <a name="input_enable_update"></a> [enable\_update](#input\_enable\_update) | Whether to enable the server update service (stackit\_server\_update\_enable). Only one enable resource per server. | `bool` | `false` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | The image ID to be used for an ephemeral disk on the server. Prefer `boot_volume` for persistent boot disks. | `string` | `null` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Name for the created key pair. Defaults to `<name>-key` when not set. Used only when `create_key_pair` is true. | `string` | `null` | no |
| <a name="input_keypair_name"></a> [keypair\_name](#input\_keypair\_name) | Name of an existing key pair to use for the server. Ignored when `create_key_pair` is true. | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Key-value string pairs to attach to the server and key pair. | `map(string)` | `{}` | no |
| <a name="input_network_interface_ids"></a> [network\_interface\_ids](#input\_network\_interface\_ids) | List of PRE-EXISTING network interface IDs to attach to the server. Combined with any interfaces created via `network_interfaces`. | `list(string)` | `null` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Map of network interfaces to CREATE and attach to the server, keyed by a stable identifier.<br/>Each value:<br/>  - `network_id`         (required) : network ID the interface is attached to.<br/>  - `name`                          : interface name.<br/>  - `security_group_ids`            : list of security group IDs to apply.<br/>  - `allowed_addresses`             : list of CIDRs allowed on the interface.<br/>  - `ipv4`                          : fixed IPv4 address.<br/>  - `security`                      : set false to disable security groups on the interface. | <pre>map(object({<br/>    network_id         = string<br/>    name               = optional(string)<br/>    security_group_ids = optional(list(string))<br/>    allowed_addresses  = optional(list(string))<br/>    ipv4               = optional(string)<br/>    security           = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_public_ips"></a> [public\_ips](#input\_public\_ips) | Map of public IPs to create, keyed by a stable identifier. Each value:<br/>  - `network_interface_id` : network interface (or virtual IP) ID to associate the public IP with. Optional (leave unset to reserve a floating IP).<br/>  - `labels`               : key-value labels for the public IP. | <pre>map(object({<br/>    network_interface_id = optional(string)<br/>    labels               = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The public SSH key to upload (e.g. `chomp(file("~/.ssh/id_ed25519.pub"))`). Required when `create_key_pair` is true. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region. If not defined, the provider region is used. | `string` | `null` | no |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | Map of service accounts to attach to the server, keyed by a STABLE identifier (NOT the email).<br/>Each value is the service account email to attach. Using a static key avoids a for\_each over a<br/>known-after-apply value (e.g. a service account email created in the same apply).<br/>Example: `{ ci = stackit_service_account.ci.email }`. | `map(string)` | `{}` | no |
| <a name="input_update_policy_id"></a> [update\_policy\_id](#input\_update\_policy\_id) | Optional update policy ID for the server update service. | `string` | `null` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | User data passed via cloud-init to the server (e.g. `file("cloud-init.yaml")` or an inline script). | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backup_enabled"></a> [backup\_enabled](#output\_backup\_enabled) | Whether the server backup service is enabled (null when not managed by this module). |
| <a name="output_backup_schedule_ids"></a> [backup\_schedule\_ids](#output\_backup\_schedule\_ids) | Map of backup schedule key to backup schedule ID. |
| <a name="output_keypair_fingerprint"></a> [keypair\_fingerprint](#output\_keypair\_fingerprint) | The fingerprint of the created key pair (null when no key pair is created). |
| <a name="output_keypair_name"></a> [keypair\_name](#output\_keypair\_name) | The name of the key pair used by the server (created or provided). |
| <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids) | Map of network interface key to created network interface ID. |
| <a name="output_network_interface_ipv4s"></a> [network\_interface\_ipv4s](#output\_network\_interface\_ipv4s) | Map of network interface key to its IPv4 address. |
| <a name="output_public_ip_ids"></a> [public\_ip\_ids](#output\_public\_ip\_ids) | Map of public IP key to public IP ID. |
| <a name="output_public_ips"></a> [public\_ips](#output\_public\_ips) | Map of public IP key to allocated IP address. |
| <a name="output_server_id"></a> [server\_id](#output\_server\_id) | The ID of the created server (null when create\_server is false). |
| <a name="output_server_name"></a> [server\_name](#output\_server\_name) | The name of the created server (null when create\_server is false). |
| <a name="output_service_account_attachment_ids"></a> [service\_account\_attachment\_ids](#output\_service\_account\_attachment\_ids) | Map of service account key to its attachment resource ID. |
| <a name="output_update_enabled"></a> [update\_enabled](#output\_update\_enabled) | Whether the server update service is enabled (null when not managed by this module). |
<!-- END_TF_DOCS -->
