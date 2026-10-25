# vm-aws

One EC2 instance with no public IP, reachable only through **SSM Session Manager** (no SSH, no key pair).
It follows the common VM contract described in [`../README.md`](../README.md).

## What it creates

- `aws_instance`:
  - Debian AMI resolved by `data "aws_ami"` (official Debian owner, `x86_64`, name matching `ami_name_pattern`).
  - `associate_public_ip_address = false`, IMDSv2 required (`http_tokens = "required"`), encrypted root volume.
  - `user_data_replace_on_change = true`: changing the user data replaces the instance.
- IAM role, `AmazonSSMManagedInstanceCore` attachment and instance profile.
- Two `precondition`s on `ip_address` (when set): it must belong to the subnet CIDR and must not be one
  of the addresses AWS reserves (first four and last).

> The official Debian AMI does not ship the SSM agent. Install it from `cloud-init`
> (`extra_runcmd`) or the instance will never register in SSM.

> With `depends_on` on the calling module, the `data "aws_subnet"` read is deferred to apply time and
> the preconditions are not evaluated during `plan`.

## Usage

```hcl
module "vm" {
  source             = "../../modules/vm-aws"
  name               = "cloud-lab-web"
  user_data          = module.cloud_init.user_data
  subnet_id          = module.network.private_subnets_ids["private-0"]
  security_group_ids = [aws_security_group.apt_ssm.id]
  instance_type      = "t3.micro"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.16 |
| aws | >= 6.0 |

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|:--------:|-------------|
| `name` | `string` | n/a | yes | Instance name (`Name` tag); also prefixes the IAM role and profile |
| `user_data` | `string` | n/a | yes | Rendered cloud-config content (not a file ID) |
| `subnet_id` | `string` | n/a | yes | Subnet of the instance |
| `security_group_ids` | `list(string)` | n/a | yes | Security groups attached to the instance |
| `instance_type` | `string` | n/a | yes | EC2 instance type. No default on purpose, because it drives the cost |
| `disk_gb` | `number` | `8` | no | Root volume size in GB |
| `ip_address` | `string` | `null` | no | Fixed private IPv4 without mask. `null` = assigned by the subnet |
| `ami_name_pattern` | `string` | `"debian-13-amd64-20260327*"` | no | AMI name pattern. Pinning the build avoids replacing the instance when a newer AMI appears |

## Outputs

| Name | Description |
|------|-------------|
| `id` | EC2 instance ID |
| `ip` | Private IP of the instance |
