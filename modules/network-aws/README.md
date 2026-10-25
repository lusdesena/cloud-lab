# network-aws

A VPC with one public and one private subnet per availability zone, an internet gateway and
**a single NAT gateway** that serves all the private subnets.

## What it creates

- `aws_vpc` with DNS support and DNS hostnames enabled.
- Subnets per AZ in `azs`, keyed `private-<i>` and `public-<i>`:
  - private: `cidrsubnet(vpc_cidr, 8, i)`
  - public: `cidrsubnet(vpc_cidr, 8, 100 + i)`
- Internet gateway and a public route table (`0.0.0.0/0` -> IGW) associated with the public subnets.
- Elastic IP and NAT gateway **in `public-0`**, and a private route table (`0.0.0.0/0` -> NAT) associated with
  the private subnets.

> **Cost and availability:** the NAT gateway bills per hour and lives in one AZ only. If that AZ fails,
> the private subnets of the other AZ lose outbound access. A NAT per AZ would remove that weakness
> at double the cost.

## Usage

```hcl
module "network" {
  source   = "../../modules/network-aws"
  name     = "cloud-lab"
  vpc_cidr = "10.20.0.0/16"
  azs      = ["eu-north-1a", "eu-north-1b"]
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
| `name` | `string` | n/a | yes | Prefix for the `Name` tag of every resource |
| `vpc_cidr` | `string` | n/a | yes | VPC CIDR. Valid CIDR with a prefix length between /16 and /20 |
| `azs` | `list(string)` | n/a | yes | Availability zones, at least 2 |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnets_ids` | Map `public-<i>` -> subnet ID |
| `private_subnets_ids` | Map `private-<i>` -> subnet ID |
| `public_subnets` | Map `public-<i>` -> `{ az, cidr }` |
| `private_subnets` | Map `private-<i>` -> `{ az, cidr }` |
| `nat_public_ip` | Public IP of the NAT gateway |
