# 0005. GitHub OIDC with two roles instead of access keys

- Status: Accepted
- Date: 2026-10-30

## Context

CI needs to run Terraform against `envs/aws`. Static access keys in
GitHub secrets would be long-lived, hard to scope per workflow and easy
to leak in logs or forks. GitHub Actions can instead present a short-lived
OIDC token that AWS exchanges for temporary credentials.

Two different needs share one repository: a `plan` that runs on every
pull request and must not change anything, and an `apply` that creates
infrastructure and must only run after a manual approval.

## Decision

One OIDC provider (`https://token.actions.githubusercontent.com`,
audience `sts.amazonaws.com`) and two roles, all created in `bootstrap/`.
AWS allows a single provider per URL and account; none existed.

Both trust policies use `StringEquals` on `aud` and on `sub`, never
`StringLike`, so no other repository can assume them.

| Role | `sub` | Session |
|---|---|---|
| `github-actions-plan` | `repo:lusdesena@48432843/cloud-lab@1434101942:pull_request` | 1 h |
| `github-actions-apply` | `repo:lusdesena@48432843/cloud-lab@1434101942:environment:aws` | 2 h |

The repository uses GitHub's immutable subject: the `sub` claim carries
the numeric IDs of the owner and the repository, not only their names
(`sub_claim_prefix` in `repos/lusdesena/cloud-lab/actions/oidc/customization/sub`).
The name-only form `repo:lusdesena/cloud-lab:...` is therefore never
presented and a trust policy written with it rejects every token. The
IDs also mean that a repository deleted and recreated under the same
name, or an account name taken by someone else after a rename, produces a
different `sub` and cannot assume the roles.

A job that declares `environment: aws` always emits the environment form
of `sub`, not the branch form. That is why `apply` is bound to the
environment: the manual approval configured there becomes part of the
trust.

`github-actions-plan`: the AWS managed policy `ReadOnlyAccess` plus a
custom policy on the state bucket: `s3:ListBucket`, `s3:GetObject` on
`aws/terraform.tfstate`, and `s3:PutObject` / `s3:DeleteObject` only on
`aws/terraform.tfstate.tflock`, because `use_lockfile` locks by writing
that object.

`github-actions-apply`: permissions for the services `envs/aws` manages
(EC2 and VPC, Elastic Load Balancing, IAM and SSM read), restricted to
`eu-north-1` with `aws:RequestedRegion`, plus read/write on the state
object and its lock. IAM actions are limited to `role/cloud-lab-*` and
`instance-profile/cloud-lab-*`, `iam:PassRole` to `ec2.amazonaws.com`,
and `iam:AttachRolePolicy` to the policy `AmazonSSMManagedInstanceCore`
through the `iam:PolicyARN` condition, so `apply` cannot attach
`AdministratorAccess` to a role it creates.

The CI roles are named `github-actions-*`, outside the `cloud-lab-*`
prefix, so `apply` cannot modify itself or the `plan` role.

## Consequences

Positive:

- No static AWS credentials in GitHub. Credentials last at most the
  session and are bound to the repository, and for `apply` to an
  environment with manual approval.
- Forks cannot assume either role: their `sub` would not match, and
  GitHub does not grant `id-token` to runs from forks.
- The trust policies are tied to the owner and repository IDs, not only
  to their names. A repository recreated under the same name cannot
  assume the roles, which is the intended behaviour.

Negative / risks:

- `ReadOnlyAccess` is broader than `plan` needs. Accepted for a lab.
- `apply` can still create any resource named `cloud-lab-*`. A permissions
  boundary would be stronger and is not implemented.
- A job using `pull_request_target` runs with write access, so the
  workflows must not use it.
- The `apply` permissions are described by service, not as a closed list
  of actions. A closed list is deferred: it will be derived from the
  `AccessDenied` errors of the first CI runs, or from CloudTrail with IAM
  Access Analyzer, and then replaced here.
- The IDs are public (GitHub API) and are written in `bootstrap/oidc.tf`.
  The `sub` also contains the names, so renaming the repository or the
  account, or recreating the repository, requires updating the values
  by hand. The rename case has not been tested.
- Verified on 2026-10-30: a `pull_request` run assumed
  `github-actions-plan`, and a `push` run on the same commit was refused
  with `Not authorized to perform sts:AssumeRoleWithWebIdentity`. The
  rejected `sub` was `...:ref:refs/heads/test/oidc`.
- Not tested: the `apply` role and the `environment:aws` subject, and the
  claim that forks get no `id-token`.

## Notes

The first version of this decision used the name-only `sub`
(`repo:lusdesena/cloud-lab:pull_request`) and the run failed with
`Not authorized to perform sts:AssumeRoleWithWebIdentity`. `terraform
validate` cannot catch it: the condition key is a free string. The cause
was found by decoding the claims of a real token in the runner, not by
reading documentation.
