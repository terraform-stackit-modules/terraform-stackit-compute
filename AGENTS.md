# Agent Guidelines

This file provides context and instructions for AI coding agents (Copilot, Cursor, Codex, etc.) working on this repository.

## Project context

This is a Terraform module for [STACKIT](https://www.stackit.de/en/), the cloud platform by Schwarz Group.
It is part of the [terraform-stackit-modules](https://github.com/terraform-stackit-modules) organization, which aims to provide community-maintained, production-grade Terraform modules for STACKIT.

### This module: compute

Provisions a STACKIT **server (VM)** and its directly-attached resources. Composable with
`terraform-stackit-network`, `terraform-stackit-security-group` and `terraform-stackit-key-pair`.

**Resources managed**
- `stackit_server` — the VM (toggled by `create_server`, via `count`). Supports the nested
  `agent` attribute (`{ provisioning_policy = ALWAYS|NEVER|INHERIT }`).
- `stackit_network_interface` — 0..N NICs the module creates, via `for_each` over `var.network_interfaces`.
- `stackit_key_pair` — optional SSH key pair (only when `create_key_pair = true` and `public_key` is set).
- `stackit_public_ip` — 0..N public IPs, via `for_each` over `var.public_ips`.
- `stackit_server_volume_attach` — attaches existing data volumes, via `for_each` over `var.attach_volume_ids`.
- `stackit_server_backup_enable` — backup service (only when `enable_backup = true`, via `count`). One per server.
- `stackit_server_backup_schedule` — 0..N backup schedules, via `for_each` over `var.backup_schedules`; `depends_on` the enable resource.
- `stackit_server_update_enable` — OS update service (only when `enable_update = true`, via `count`). One per server.
- `stackit_server_service_account_attach` — 0..N service-account attachments, via `for_each` over `var.service_accounts` (a **map keyed by a stable id**, value = email).

**Key inputs** — `project_id` (req), `name` (req), `machine_type` (req), `boot_volume`
(`{source_type, source_id, size?, performance_class?, delete_on_termination?}`),
`availability_zone`, `image_id`, `user_data` (cloud-init), `agent` (`{provisioning_policy?}`),
`network_interfaces` (map of NICs to CREATE: `{network_id, name?, security_group_ids?, allowed_addresses?, ipv4?, security?}`),
`network_interface_ids` (list of PRE-EXISTING NIC IDs),
`create_key_pair`/`public_key`/`keypair_name`, `public_ips`, `attach_volume_ids`, `labels`,
`enable_backup`/`backup_policy_id`/`backup_schedules` (map: `{name, rrule, enabled?, backup_name, retention_period, volume_ids?}`),
`enable_update`/`update_policy_id`,
`service_accounts` (map of `{stable_key => service_account_email}`).

**Outputs** — `server_id`, `server_name`, `keypair_name`, `keypair_fingerprint`,
`public_ips` (map key→IP), `public_ip_ids`, `network_interface_ids`, `network_interface_ipv4s`,
`backup_enabled`, `backup_schedule_ids` (map key→id), `update_enabled`,
`service_account_attachment_ids` (map key→attachment id).

**Gotchas**
- `boot_volume` is a nested single object → assign with `= { ... }`, never `dynamic {}`.
  `size` is required when `source_type = "image"`.
- A server needs at least one NIC to be reachable. The server attaches the union of NICs
  created via `network_interfaces` and IDs passed via `network_interface_ids`.
- Provide EITHER `create_key_pair`+`public_key` (module creates the key) OR `keypair_name`
  (reuse an existing key, e.g. from `terraform-stackit-key-pair`); the module wires the
  server's `keypair_name` accordingly.
- **Backup**: `backup_schedules` require `enable_backup = true`; the module gates the schedules
  with `depends_on` on `stackit_server_backup_enable`. Only ONE enable resource per server.
- **Update**: only ONE `stackit_server_update_enable` per server.
- **`service_accounts` is a MAP keyed by a stable identifier, NOT `toset(list-of-emails)`.** The
  email of a service account created in the same apply is known-after-apply; a `for_each` over
  `toset([sa.email])` would fail at plan (`Invalid for_each argument`). Keying by a static id
  (value = email) keeps `for_each` over known keys. Same class of bug as the earlier keypair
  `count`-on-unknown fix.
- All backup/update toggles are `count`-gated on plain booleans (`enable_backup`, `enable_update`)
  — never gate a `count`/`for_each` on a value that is only known after apply.
- `examples/basic` is self-contained (requires only `project_id`): it builds the network via
  the published `terraform-stackit-network` module and generates a throwaway RSA key with the
  `tls` provider (`trimspace(tls_private_key.this.public_key_openssh)`) — STACKIT rejects a
  malformed public key at apply, so a real key is required, not a hand-crafted placeholder.
- `examples/{backup,update,service-account-attach}` follow the same self-contained pattern
  (each on its own CIDR: `.101`/`.102`/`.103`) and are each covered by a Terratest test. They
  provision real servers on apply.

## Repository structure

```
.
├── main.tf                  # Module resources
├── variables.tf             # Input variables (all must be documented)
├── outputs.tf               # Output values (all must be documented)
├── versions.tf              # Terraform and provider version constraints
├── examples/
│   ├── basic/                   # Minimal working example (Terratest)
│   ├── backup/                  # Server backup enable + schedule (Terratest)
│   ├── update/                  # Server OS update enable (Terratest)
│   └── service-account-attach/  # Creates + attaches a service account (Terratest)
├── test/
│   ├── examples_basic_test.go                   # Terratest: basic
│   ├── examples_backup_test.go                  # Terratest: backup
│   ├── examples_update_test.go                  # Terratest: update
│   └── examples_service_account_attach_test.go  # Terratest: service-account-attach
└── .github/
    └── workflows/           # CI/CD pipelines
```

## Coding conventions

- Terraform version: `>= 1.3`
- Provider: `stackitcloud/stackit >= 0.113.0` — do NOT use `hashicorp/stackit`
- All variables must have `description` and `type`
- All outputs must have `description`
- Naming convention: `snake_case` for all resources, variables, and outputs
- No hardcoded values — use variables
- `project_id` is always a required variable of type `string`
- Use `count` only for on/off toggles (`create_security_group`), use `for_each` for resource iteration
- `protocol`, `port_range`, and `icmp_parameters` on `stackit_security_group_rule` are `nested_type/single` attributes — use `= {}` syntax, NOT `dynamic {}` blocks

## CI/CD

- `pre-commit` runs `terraform_fmt`, `terraform_validate`, `terraform_docs`, `terraform_tflint` on every PR
- `README.md` is auto-generated by `terraform-docs` — never edit it directly
- Releases are managed by `semantic-release` using conventional commits
- Terratest runs real infrastructure tests against STACKIT — requires `STACKIT_SERVICE_ACCOUNT_KEY` and `STACKIT_PROJECT_ID` secrets

## Commit convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new feature
- `fix:` bug fix
- `improvement:` enhancement
- `docs:` documentation
- `refactor:` refactoring
- `test:` tests
- `ci:` CI/CD changes
- `chore:` maintenance (skipped in changelog)

## What to avoid

- Do not edit `README.md` directly
- Do not use `count` for resource iteration — prefer `for_each`
- Do not pin provider versions to an exact version in modules — use `>=`
- Do not commit `.terraform/`, `*.tfstate`, or `*.tfstate.backup`
- Do not add `dynamic` blocks for `nested_type/single` attributes in the STACKIT provider

## Inspiration Note
Inspired by the excellent work of [terraform-aws-modules](https://github.com/terraform-aws-modules) by Anton Babenko and the community.
