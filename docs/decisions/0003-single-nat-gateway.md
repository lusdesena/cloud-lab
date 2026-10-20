# 0003. Single NAT Gateway

- Status: Accepted
- Date: 2026-10-20

## Context

The instances in the private subnets need outbound Internet access
(package installs, updates) without being reachable from outside. In AWS
that is a NAT Gateway in a public subnet, plus a route `0.0.0.0/0` from
the private route table to it.

A NAT Gateway is zonal and is billed per hour while it exists, plus per
GB processed (roughly 33 USD/month before traffic). The network spans two
AZs because the ALB requires at least two.

## Decision

`network-aws` creates **one** NAT Gateway, in the first public subnet
(`public-0`), with one Elastic IP and a single private route table shared
by all the private subnets.

The NAT and its EIP are ephemeral: they exist only during a session
(`apply`, work, `destroy`). The VPC, subnets, IGW and public route table
stay applied because they are free.

## Consequences

Positive:

- Cost is a third of a per-AZ NAT, and it is only paid during sessions.
- One route table and one NAT keep the module simple.

Negative / risks:

- The NAT is a single point of failure. If its AZ (`eu-north-1a`) fails,
  the private subnets in the other AZ also lose outbound access.
- Traffic from the second AZ crosses AZs to reach the NAT, which adds
  inter-AZ data transfer cost.
- Forgetting the `destroy` keeps billing around 33 USD/month. Mitigation:
  destroy with
  `terraform destroy -target=module.network.aws_nat_gateway.main -target=module.network.aws_eip.main`
  and keep a budget alert.

## Alternatives considered

- **One NAT Gateway per AZ**, each with its own private route table. This
  is the production pattern: an AZ failure only affects its own subnets.
  It doubles the NAT cost and needs one route table per AZ, which is not
  worth it for a lab with no availability requirement. Worth adopting
  for shared or production use.
- **No NAT, VPC endpoints only** (SSM, S3). Cheaper, but the instances
  could not install packages from the Internet.
- **NAT instance** (an EC2 doing the translation). Cheaper than the
  managed service, but it has to be patched and sized by hand.
