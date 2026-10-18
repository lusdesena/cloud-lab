# 0001. Bootstrap local state

- Status: Accepted
- Date: 2026-10-18

## Context

`envs/homelab` and `envs/aws` need a remote backend in S3 to store their
state with versioning, encryption and locking. That bucket has to be
created by Terraform too, but it can't be created by the same
environments that store their state in it: we can't use a resource that
doesn't exist yet.

## Decision

`bootstrap/` is an independent Terraform root that provisions the S3
bucket. Its state is local and gitignored, since it can contain sensitive
data. The bucket stores the state of each environment under its own key:
`homelab/terraform.tfstate` and `aws/terraform.tfstate`.

Bucket configuration:

- Versioning: keeps previous versions of the state file, so a corrupted
  or wrongly overwritten state can be recovered.
- Encryption: SSE-S3 (AES256) encrypts the state at rest, since it can
  contain secrets. KMS would add key control and audit, but also cost and
  key management that a single-operator lab doesn't need.
- Public access block: blocks any public access, so a misconfigured ACL
  or policy can't expose the state.
- TLS-only policy: denies any request not using TLS, so the state is
  never sent in clear text.
- Deletion protection: `prevent_destroy` makes Terraform refuse any plan
  that would destroy the bucket, protecting against an accidental
  `terraform destroy`. It is a guard rail, not a security control: it
  does not cover deletion through the console or CLI, nor removing the
  resource block from the code.
- Name: `cloud-lab-tfstate-<account_id>-<region>` is unique and fully
  derived from the account, not from the state. A `random_id` suffix
  would change if the local state were lost, and the next apply would
  create a new bucket instead of finding the existing one.

Locking: `use_lockfile = true` (Terraform >= 1.11) writes a lock file
next to the state in S3, so two concurrent applies cannot modify it at
once.

## Consequences

Positive:

- The backend is reproducible and reviewable as code, with no manual bucket.
- `envs/*` keep their state in S3 and never depend on the local file.
- No DynamoDB table to pay for or maintain.

Negative / risks:

- The local state of `bootstrap/` is a single point of failure. If it is
  lost, Terraform no longer recognises the bucket as its own. The bucket
  and the state of the environments are untouched, because they live in
  S3, and the bucket is reconnected to the code with `terraform import`,
  one resource at a time. Mitigation: keep a copy of the state outside
  the repository.
- `prevent_destroy` is a guard rail, not a security control: it does not
  cover deletion through the console or CLI, nor removing the resource
  block from the code.
- SSE-S3 gives no key-level access control or audit trail; KMS would.

## Alternatives considered

- **Create the bucket by hand.** Simple, but not reproducible or
  reviewable, and its configuration can drift unnoticed.
- **DynamoDB for locking.** The legacy pattern. Since Terraform 1.11 S3
  locks natively, so the table would add cost and moving parts for
  nothing.
- **`random_id` in the name.** Avoids global name collisions, but the name
  would depend on a state that is local and can be lost.
- **KMS encryption.** Stronger control and audit, but more setup and cost
  than a single-operator lab needs. Worth revisiting for shared or
  production use.
