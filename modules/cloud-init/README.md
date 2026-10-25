# cloud-init

Renders a cloud-config document. It only produces text: it knows nothing about any provider, so the same
output feeds both `vm-aws` (as `user_data`) and `vm-proxmox` (uploaded as a snippet).

## What it renders

- `hostname` and one sudo user (`sudo: ALL=(ALL) NOPASSWD:ALL`, bash shell), with optional SSH keys.
- `package_update: true` and the list of `packages`.
- `runcmd`: the entries of `extra_runcmd`, in order. The module starts no service by itself.

## Usage

```hcl
module "cloud_init" {
  source   = "../../modules/cloud-init"
  username = "admin"
  hostname = "web"
  packages = ["nginx"]

  extra_runcmd = ["systemctl enable --now nginx.service"]
}

# module.cloud_init.user_data -> the rendered text
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.16 |

No providers.

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|:--------:|-------------|
| `username` | `string` | n/a | yes | User created on the VM. Must not be empty or `root` |
| `hostname` | `string` | n/a | yes | Hostname of the VM |
| `packages` | `list(string)` | `[]` | no | Packages to install |
| `ssh_authorized_keys` | `list(string)` | `[]` | no | SSH public keys for the user |
| `extra_runcmd` | `list(string)` | `[]` | no | `runcmd` entries run in order (enable services, install the SSM agent on AWS…) |

## Outputs

| Name | Description |
|------|-------------|
| `user_data` | Rendered cloud-config content |
