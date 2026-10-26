# Modules

A **common, soft contract** for the VM modules: `vm-proxmox` and `vm-aws` meet the same core and add
whatever is specific to each provider on top. There is one environment per provider (`envs/homelab`,
`envs/aws`), and the user data is rendered once in `cloud-init` and reused.

## Common VM contract

### Inputs

| Variable | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | yes | VM name |
| `disk_gb` | `number` | no (default per module: 20 on `vm-proxmox`, 8 on `vm-aws`) | Root disk size in GB |
| `user_data` | `string` | yes | Rendered cloud-config **content** (not an ID) |
| `ip_address` | `string` | no (`null`) | Fixed private IP. `null` = assigned by the environment (DHCP / subnet) |

### Outputs

| Output | Type | Description |
|---|---|---|
| `id` | `string` | VM identifier in the provider (VM ID / instance ID) |
| `ip` | `string` | The VM's actual IP, whether it was fixed or not |

## Provider-specific (outside the contract)

| Module | Own variables |
|---|---|
| `vm-proxmox` | `node_name`, `cpu`, `memory`, `datastore_id`, `snippets_datastore_id`, `bridge`, `template_vm_id`, `gateway`, `prefix_length` (all with a default) · `vm_id` (required) |
| `vm-aws` | `subnet_id`, `security_group_ids`, `instance_type` (required, no default because it drives the cost), `ami_name_pattern` (default: a pinned Debian 13 build) |

Notes on `vm-aws`:

- **No `key_name`**: access is through SSM only, with no SSH. The SSH keys passed to `cloud-init` are not used to log in.
- **No `ami_id`**: the AMI is resolved inside the module with `data "aws_ami"` from `ami_name_pattern`. Pinning the build in the pattern avoids replacing the instance when newer AMIs appear; updating it is a reviewable code change.
- **No `instance_profile`**: the module creates it (an IAM role with `AmazonSSMManagedInstanceCore` plus an instance profile), because SSM is the only way in.
- `cpu` and `memory` do not exist on AWS: sizing is `instance_type`.

## `cloud-init`

It only renders: it takes a user, keys and packages and returns the cloud-config **text**. It knows nothing
about any provider.

- `vm-aws` passes it as-is to the instance's `user_data`.
- `vm-proxmox` uploads it as a snippet (`proxmox_virtual_environment_file`) and references its ID in
  `initialization.user_data_file_id`.

Each module has its own README with the full list of inputs and outputs.
