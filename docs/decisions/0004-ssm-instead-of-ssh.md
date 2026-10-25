# 0004. SSM Session Manager instead of SSH

- Status: Accepted
- Date: 2026-10-24

## Context

The EC2 instance in `envs/aws` runs in a private subnet and only needs
to be administered by one operator. Opening SSH would mean a key pair to
store and rotate, an inbound rule on port 22, and a path from the
Internet (or a bastion) to the instance, all for a lab whose only entry
point is meant to be the ALB.

AWS Systems Manager Session Manager gives a shell over an outbound
HTTPS connection started by the SSM Agent, so the instance needs no
inbound port. Access is controlled by IAM instead of keys.

Two constraints shape the design:

- The official Debian AMI does not ship the SSM Agent, and the package
  is not in the Debian repositories. An IAM role alone is not enough:
  the agent has to be installed on the instance.
- The agent needs to reach the SSM service endpoints. In this lab that
  path is the NAT gateway from ADR 0003.

## Decision

The instance is reachable **only** through Session Manager: no SSH and
no key pair.

In `modules/vm-aws`:

- `aws_instance` has no `key_name` and sets
  `associate_public_ip_address = false`. It lives in a private subnet.
- The module creates the IAM role (trust policy for `ec2.amazonaws.com`),
  attaches the AWS managed policy `AmazonSSMManagedInstanceCore` and
  wraps it in an instance profile. The module owns this because SSM is
  the only way in.
- IMDSv2 is required (`http_tokens = "required"`) and the root volume is
  encrypted.

In `envs/aws`:

- The security group has no inbound rule for SSH. Its only ingress is
  TCP 80 from the ALB security group, and its egress is TCP 80 and 443.
- The SSM Agent is installed on first boot by the `cloud-init` module
  through `extra_runcmd`: download the AWS `.deb`, `dpkg -i`, and
  `systemctl enable --now amazon-ssm-agent`. The detail is specific to
  AWS and Debian, so it lives in the environment. The `vm-aws` module
  and the common VM contract do not change.

Access from the workstation uses the AWS CLI with `session-manager-plugin`
installed: `aws ssm start-session --target <instance-id>`.

Verified on 2026-10-24: the instance registered in SSM as `Online`,
`start-session` opened a shell, and `systemctl status amazon-ssm-agent`
showed the agent running.

## Consequences

Positive:

- No inbound port, no key pair and no bastion: nothing to rotate, leak or
  expose.
- Access is governed by IAM, not by a key file.
- The instance needs no public IP or Elastic IP. Outbound traffic goes
  through the NAT and inbound traffic only through the ALB.
- The module stays provider-clean: the Debian-specific agent install
  does not leak into its contract.

Negative / risks:

- There is no emergency SSH. If the agent is not running, the instance
  loses IAM permissions, or outbound connectivity breaks (NAT destroyed,
  missing route, security group without egress 443), there is no way in.
  The recovery path is to read the console output and recreate the
  instance (`user_data_replace_on_change = true`). A serial console or
  other break-glass path has not been tried.
- Administration depends on an AWS service and on the AWS CLI plus
  `session-manager-plugin` on the client. Without the plugin,
  `start-session` fails.
- The agent is downloaded from the `latest` path with no pinned version
  and no checksum verification, so a new instance may get a newer agent
  than an older one.
- Registration is not immediate: the instance appears as `Online` a few
  minutes after boot (cloud-init plus download and install). Before that,
  `start-session` fails with `TargetNotConnected`.
- The agent depends on the NAT, which is ephemeral (ADR 0003). With the
  NAT destroyed, the instance cannot be reached even if it is running.
- A shell opened this way runs as `ssm-user`, not as the user created by
  `cloud-init`.
- Session logging to S3 or CloudWatch is not configured.

## Alternatives considered

- **SSH through a bastion or an Elastic IP.** The familiar pattern, but
  it brings a key pair, an inbound rule on port 22 and a host to harden
  and pay for. It reverses the goal of having the ALB as the only entry
  point.
- **EC2 Instance Connect.** Avoids long-lived keys, but still uses SSH
  and needs port 22 reachable from the connecting side. Not evaluated in
  this lab.
- **VPC endpoints for SSM instead of the NAT.** The agent talks to
  `ssm`, `ssmmessages` and `ec2messages`, so interface endpoints for
  those services would remove the NAT dependency for administration. The
  instance would still need Internet access to install nginx and download
  the agent, which is why the lab keeps the NAT (ADR 0003). Not built or
  priced here. Worth revisiting if the instances stop needing general
  outbound access.
- **Amazon Linux, which ships the SSM Agent.** It would remove the
  `extra_runcmd` step. Debian was kept on purpose, and the agent install
  is the cost of that choice.
