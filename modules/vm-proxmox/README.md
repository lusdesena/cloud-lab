# vm-proxmox

One Proxmox VM cloned from a cloud-init template, plus the snippet that carries its user data.
It follows the common VM contract described in [`../README.md`](../README.md).

## What it creates

- `proxmox_virtual_environment_file`: the rendered user data as a snippet named `cloud-config-<vm_id>.yml`.
- `proxmox_virtual_environment_vm`: clone of `template_vm_id`, QEMU guest agent enabled, DHCP or a fixed IP.
- Checks on `ip_address` (when set):
  - `precondition`: valid IPv4 and in the same subnet as `gateway`.
  - `postcondition`: the IP is among the addresses reported by the guest agent.

> The guest agent must run inside the template. The `postcondition` and the `ip` output depend on it.

> The snippets datastore (`snippets_datastore_id`) must have the `snippets` content type enabled.

## Usage

```hcl
module "vm" {
  source     = "../../modules/vm-proxmox"
  name       = "tf-web-01"
  vm_id      = 301
  node_name  = "pve"
  user_data  = module.cloud_init.user_data
  ip_address = "192.0.2.151"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.16 |
| bpg/proxmox | >= 0.116.0 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|:--------:|-------------|
| `name` | `string` | n/a | yes | VM name |
| `vm_id` | `number` | n/a | yes | Proxmox VM ID |
| `node_name` | `string` | n/a | yes | Proxmox node |
| `user_data` | `string` | n/a | yes | Rendered cloud-config content (not a file ID) |
| `disk_gb` | `number` | `20` | no | Disk size in GB |
| `ip_address` | `string` | `null` | no | Fixed IPv4 without mask. `null` = DHCP |
| `cpu` | `number` | `1` | no | Cores |
| `memory` | `number` | `2048` | no | Memory in MB |
| `datastore_id` | `string` | `"local-zfs"` | no | Datastore for the disk and the cloud-init drive |
| `snippets_datastore_id` | `string` | `"local"` | no | Datastore for snippets |
| `bridge` | `string` | `"vmbr0"` | no | Network bridge |
| `template_vm_id` | `number` | `9000` | no | VM ID of the template to clone |
| `gateway` | `string` | `"192.0.2.1"` | no | IPv4 gateway. Only used when `ip_address` is set |
| `prefix_length` | `number` | `24` | no | Subnet prefix length. Only used when `ip_address` is set |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Proxmox VM ID |
| `ip` | The fixed IP, or the one reported by the guest agent |
