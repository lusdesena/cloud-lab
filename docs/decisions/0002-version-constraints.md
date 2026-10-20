# 0002. Version constraints for Terraform and providers

- Status: Accepted
- Date: 2026-10-20

## Context

Each root (`bootstrap/`, `envs/aws`, `envs/homelab`) and each module
(`modules/*`) declares its own `required_version` and `required_providers`.
They had drifted with no rule behind them:

- Two Terraform floors: `~> 1.11` in two roots and `~> 1.16` everywhere
  else. Both forms mean `>= X, < 2.0`, so only the floor differed. Since
  constraints from root and modules are combined, the `1.11` in those
  roots was misleading: the modules already required 1.16.
- Three provider pin styles: `~> 6.0` (aws), exact versions (proxmox,
  http) and `>= 0.116.0` (proxmox in `vm-proxmox`).
- A module (`network-aws`) with a pessimistic `~> 6.0` pin.
- Mixed formatting (`~>1.11` and `~> 1.11`), which `terraform fmt` does
  not fix.

## Decision

Four rules.

1. **Modules declare a floor (`>=`); roots declare a ceiling (`~>`) and
   commit the lock file.**
   - A module states the minimum it needs. An upper bound in a module
     blocks whoever consumes it, and here that consumer is a root of
     this same repo.
   - The root decides which version is actually used.
   - The `.terraform.lock.hcl` fixes the exact version and hashes. An
     exact pin in the root duplicates the lock and forces changing two
     places to upgrade.

2. **The Terraform floor is the version we test with, not the oldest that
   might work.** Everything uses 1.16: roots `~> 1.16`, modules
   `>= 1.16`. Declaring `>= 1.11` without testing it would be an empty
   promise. Upgrading Terraform is one sweep over all `versions.tf`.

3. **Pre-1.0 providers are bounded at the minor.** `bpg/proxmox` is 0.x,
   where a minor release may contain breaking changes, so it uses
   `~> 0.116.0` (patches only). `~> 0.116` would allow 0.117 up to 1.0.
   Stable providers are bounded at the major: `~> 6.0` (aws),
   `~> 3.4` (http).

4. **Format is `~> X.Y` with a space, in every file.**

Resulting constraints:

| File | `required_version` | Providers |
|---|---|---|
| `bootstrap/`, `envs/*` | `~> 1.16` | aws `~> 6.0` · proxmox `~> 0.116.0` · http `~> 3.4` |
| `modules/network-aws` | `>= 1.16` | aws `>= 6.0` |
| `modules/vm-proxmox` | `>= 1.16` | proxmox `>= 0.116.0` |
| `modules/cloud-init` | `>= 1.16` | none (no resources or data sources) |

A module only declares the providers it actually uses. Provider
configuration (`provider` blocks) stays in the root; modules inherit it.

## Consequences

Positive:

- One rule per layer, easy to review and to apply to new modules.
- Modules are not tied to a specific provider version; the root and the
  lock file control upgrades in a single place.
- Breaking changes in proxmox cannot arrive through a plain
  `init -upgrade`.

Negative / risks:

- Floors claim only what is tested. If a module starts using a feature
  from a newer provider, its floor must be raised by hand; nothing
  enforces it.
- `~> 0.116.0` needs a manual bump of the constraint for each proxmox
  minor release. This is intended: each one is reviewed.
- All files move together on a Terraform upgrade (rule 2). It is a small
  sweep, but it must not be forgotten.

## Alternatives considered

- **Exact pins in roots (`0.116.0`).** Maximum reproducibility, but the
  lock file already provides it. Upgrades need editing the constraint and
  the lock.
- **`~>` everywhere, modules included.** Uniform, but a pessimistic bound
  in a module limits every consumer and gives no benefit in return.
- **Keep the lowest Terraform floor that might work (`1.11`).** Wider
  compatibility, but unverified; with a single operator and a single
  installed version there is nobody to benefit from it.
- **`~> 0.116` for proxmox.** Allows every 0.x minor up to 1.0, where
  breaking changes are legitimate under semver.
