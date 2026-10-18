# Módulos

Contrato **común y blando** para los módulos de VM: `vm-proxmox` y `vm-aws` (S10) cumplen el mismo
núcleo y añaden por encima lo propio de cada provider. Un env por provider (`envs/homelab`,
`envs/aws`); el user-data se renderiza una sola vez en `cloud-init` y se reutiliza.

## Contrato común de VM

### Inputs

| Variable | Tipo | Obligatoria | Descripción |
|---|---|---|---|
| `name` | `string` | sí | Nombre de la VM |
| `cpu` | `number` | sí | vCPU |
| `memory` | `number` | sí | Memoria en MB |
| `disk_gb` | `number` | sí | Disco raíz en GB |
| `user_data` | `string` | sí | **Contenido** cloud-config renderizado (no un ID) |
| `ip_address` | `string` | no (`null`) | IP privada fija. `null` = la asigna el entorno (DHCP / subred) |

### Outputs

| Output | Tipo | Descripción |
|---|---|---|
| `id` | `string` | Identificador de la VM en el provider (VMID / instance id) |
| `ip` | `string` | IP real de la VM, se haya fijado o no |

## Específico de cada provider (fuera del contrato)

| Módulo | Variables propias |
|---|---|
| `vm-proxmox` | `node_name`, `datastore_id`, `bridge`, `template_vm_id`, `gateway` (todas con default) · `vm_id` |
| `vm-aws` | `key_name` (si se usa clave de EC2; en Proxmox las claves viajan dentro de `user_data`), `subnet_id`, `security_group_ids`, `instance_type`, `ami_id`, instance profile |

## `cloud-init`

Solo renderiza: recibe usuario, claves y paquetes y devuelve el **texto** cloud-config. No conoce
ningún provider.

- `vm-aws` lo pasa tal cual al campo `user_data` de la instancia.
- `vm-proxmox` lo sube como snippet (`proxmox_virtual_environment_file`) y referencia su ID en
  `initialization.user_data_file_id`.

## Deuda de S5

- [x] `cloud-init` solo renderiza y devuelve `user_data`; el snippet vive en `vm-proxmox`.
- [x] Quitado `required_providers` de Proxmox en `cloud-init`.
- [x] VM y snippet movidos a `vm-proxmox` con bloques `moved` (`moved.tf`); `plan` = 0 to destroy.
- [ ] `terraform apply -var username=abel` para escribir las nuevas direcciones en el state.
- [ ] `for_each` sobre un `map` para `tf-web-01` y `tf-web-02`.
