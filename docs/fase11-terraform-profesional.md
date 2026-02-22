# FASE 11 - Terraform Profesional (Nivel Entrevista)

> De Terraform básico a Terraform nivel producción

---

## 🎯 Objetivo

Transformar tu configuración de Terraform de nivel básico a **nivel profesional** implementando:
- Backend remoto con estado compartido
- Locking para trabajo en equipo
- Ambientes separados (dev/prod)
- Seguridad mejorada en NSG

---

## 📚 Conceptos Clave

### 🔹 Backend Remoto

**Problema con estado local:**
- ❌ Archivo `terraform.tfstate` en tu máquina
- ❌ No se puede trabajar en equipo
- ❌ Riesgo de pérdida de datos
- ❌ No hay historial de cambios

**Solución con backend remoto:**
- ✅ Estado en Azure Storage Account
- ✅ Accesible por todo el equipo
- ✅ Backup automático
- ✅ Versionado
- ✅ Locking automático

### 🔹 State Locking

**¿Qué es?**
Mecanismo que previene que dos personas ejecuten `terraform apply` al mismo tiempo.

**¿Por qué es importante?**
- Evita corrupción del estado
- Previene conflictos
- Garantiza consistencia

**En Azure:**
Se implementa automáticamente con Azure Storage Account usando **blob leases**.

### 🔹 Ambientes (Environments)

**Separación de ambientes:**
- `dev` → Desarrollo (recursos pequeños, menos costo)
- `qa` → Testing (similar a producción)
- `prod` → Producción (recursos robustos)

**Implementación:**
Archivos `.tfvars` con valores específicos por ambiente.

---

## 🏗️ Arquitectura Implementada

```
┌─────────────────────────────────────────────┐
│         Azure Storage Account               │
│         (tfstatedevops2024)                 │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Container: tfstate                 │   │
│  │  ├── terraform.tfstate (locked)     │   │
│  │  └── Versioning enabled             │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    ▲
                    │
        ┌───────────┴───────────┐
        │                       │
    Developer 1            Developer 2
    (terraform apply)      (espera lock)
```

---

## 🛠️ Implementación Paso a Paso

### Paso 1: Crear Storage Account para el Estado

```bash
# Crear Resource Group
az group create \
  --name rg-terraform-state \
  --location westus2

# Crear Storage Account (nombre único)
az storage account create \
  --name tfstatedevops2024 \
  --resource-group rg-terraform-state \
  --location westus2 \
  --sku Standard_LRS \
  --encryption-services blob

# Crear contenedor
az storage container create \
  --name tfstate \
  --account-name tfstatedevops2024
```

**Resultado:**
- ✅ Storage Account creado
- ✅ Contenedor `tfstate` listo
- ✅ Encriptación habilitada

---

### Paso 2: Configurar Backend en Terraform

**Crear `terraform/backend.tf`:**

```hcl
# Backend configuration for remote state
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatedevops2024"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

**Explicación:**
- `resource_group_name`: RG donde está el Storage Account
- `storage_account_name`: Nombre del Storage Account
- `container_name`: Contenedor blob
- `key`: Nombre del archivo de estado

---

### Paso 3: Crear Archivos de Ambientes

**Estructura:**
```
terraform/
├── environments/
│   ├── dev.tfvars
│   └── prod.tfvars
```

**`environments/dev.tfvars`:**
```hcl
resource_group_name = "rg-devops-dev"
location            = "westus2"
vm_size             = "Standard_B2s"      # Más pequeño
admin_username      = "azureuser"
environment         = "dev"
```

**`environments/prod.tfvars`:**
```hcl
resource_group_name = "rg-devops-prod"
location            = "westus2"
vm_size             = "Standard_D2s_v5"   # Más robusto
admin_username      = "azureuser"
environment         = "prod"
```

---

### Paso 4: Agregar Variables Nuevas

**Actualizar `variables.tf`:**

```hcl
variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "allowed_ip" {
  description = "IP permitida para acceso SSH/HTTP"
  type        = string
  default     = "0.0.0.0/0"  # Cambiar por tu IP
}
```

---

### Paso 5: Mejorar Seguridad del NSG

**Antes (INSEGURO):**
```hcl
source_address_prefix = "*"  # ❌ Abierto a todo el mundo
```

**Después (SEGURO):**
```hcl
source_address_prefix = var.allowed_ip  # ✅ Solo tu IP
```

**Obtener tu IP:**
```bash
curl ifconfig.me
# Resultado: 190.84.117.210
```

**Actualizar `main.tf`:**
```hcl
security_rule {
  name                       = "SSH"
  priority                   = 1000
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.allowed_ip  # ✅ Solo tu IP
  destination_address_prefix = "*"
}
```

Aplicar lo mismo a todas las reglas: HTTP, App, K8s, Grafana, Prometheus.

---

### Paso 6: Migrar Estado Local a Remoto

```bash
cd terraform

# Inicializar con nuevo backend
terraform init -reconfigure

# Terraform preguntará si quieres copiar el estado
# Responde: yes
```

**Salida esperada:**
```
Do you want to copy existing state to the new backend?
  Enter a value: yes

Successfully configured the backend "azurerm"!
```

---

### Paso 7: Verificar Estado Remoto

```bash
# Ver recursos en el estado
terraform state list

# Verificar en Azure
az storage blob list \
  --account-name tfstatedevops2024 \
  --container-name tfstate \
  --output table
```

**Deberías ver:**
```
Name                   Blob Type    Length
---------------------  -----------  --------
terraform.tfstate      BlockBlob    18917
```

---

### Paso 8: Aplicar Cambios de Seguridad

```bash
# Ver cambios
terraform plan

# Aplicar solo NSG (evitar crear otros recursos)
terraform apply -target=azurerm_network_security_group.main

# Confirmar: yes
```

**Resultado:**
```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

---

## 🚀 Uso de Ambientes

### Desplegar en DEV

```bash
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Desplegar en PROD

```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

### Diferencias entre ambientes

| Recurso | DEV | PROD |
|---------|-----|------|
| Resource Group | `rg-devops-dev` | `rg-devops-prod` |
| VM Size | `Standard_B2s` | `Standard_D2s_v5` |
| Costo/mes | ~$30 | ~$70 |

---

## 📊 Estructura Final del Proyecto

```
terraform/
├── backend.tf              # Configuración de backend remoto
├── provider.tf             # Provider Azure
├── variables.tf            # Variables (con environment y allowed_ip)
├── main.tf                 # Recursos (NSG con seguridad mejorada)
├── outputs.tf              # Outputs
├── aks.tf                  # Kubernetes (opcional)
├── environments/
│   ├── dev.tfvars         # Variables de desarrollo
│   └── prod.tfvars        # Variables de producción
├── .gitignore             # Ignorar .terraform/ y *.tfstate
└── .terraform/            # Providers (no subir a Git)
```

---

## 🔐 Seguridad Implementada

### Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| Estado | Local (inseguro) | Remoto (Azure Storage) |
| Locking | ❌ No | ✅ Sí (automático) |
| NSG SSH | `0.0.0.0/0` | `190.84.117.210/32` |
| NSG HTTP | `0.0.0.0/0` | `190.84.117.210/32` |
| NSG K8s | `0.0.0.0/0` | `190.84.117.210/32` |
| Ambientes | ❌ No | ✅ dev/prod separados |

---

## 🎓 Conceptos para Entrevistas

### Pregunta 1: ¿Cómo manejas el estado de Terraform en equipo?

**Respuesta:**
> "Uso backend remoto en Azure Storage Account con locking automático. Esto permite que múltiples desarrolladores trabajen sin conflictos. El estado se almacena en un blob con versionado habilitado y encriptación. Además, implemento RBAC para controlar quién puede modificar el estado."

### Pregunta 2: ¿Cómo evitas conflictos de estado?

**Respuesta:**
> "Azure Storage implementa locking mediante blob leases. Cuando alguien ejecuta `terraform apply`, se adquiere un lease que bloquea el estado. Si otro desarrollador intenta aplicar cambios, Terraform espera hasta que se libere el lock. Esto previene corrupción del estado."

### Pregunta 3: ¿Cómo separas ambientes?

**Respuesta:**
> "Uso archivos `.tfvars` por ambiente (dev.tfvars, prod.tfvars) con valores específicos como tamaño de VM, región, tags. También puedo usar workspaces de Terraform o backends separados por ambiente. Prefiero `.tfvars` porque es más explícito y fácil de auditar."

### Pregunta 4: ¿Qué pasa si se pierde el estado?

**Respuesta:**
> "Con backend remoto en Azure Storage, tengo versionado habilitado. Puedo recuperar versiones anteriores del estado. Además, implemento backups automáticos del Storage Account. Como último recurso, puedo usar `terraform import` para reconstruir el estado desde los recursos existentes en Azure."

### Pregunta 5: ¿Cómo haces rollback de infraestructura?

**Respuesta:**
> "Uso Git para versionar el código de Terraform. Si necesito rollback, hago `git revert` al commit anterior y ejecuto `terraform apply`. El estado remoto se actualiza automáticamente. También puedo usar `terraform state mv` o `terraform state rm` para operaciones más granulares."

---

## 🧪 Validación

### Verificar backend remoto

```bash
# Ver configuración actual
terraform show

# Ver estado remoto
az storage blob show \
  --account-name tfstatedevops2024 \
  --container-name tfstate \
  --name terraform.tfstate
```

### Probar locking

**Terminal 1:**
```bash
terraform apply
# Mantener abierto
```

**Terminal 2:**
```bash
terraform apply
# Debería mostrar: "Error acquiring the state lock"
```

### Verificar seguridad NSG

```bash
# Ver reglas actuales
az network nsg rule list \
  --resource-group rg-terraform-demo \
  --nsg-name nsg-terraform \
  --output table

# Verificar que source_address_prefix sea tu IP
```

---

## 💰 Costos

### Storage Account para estado

- **Costo:** ~$0.02/mes
- **Transacciones:** Incluidas en tier gratuito
- **Redundancia:** LRS (Local)

### Total adicional

- **Antes:** $0
- **Después:** ~$0.02/mes
- **Beneficio:** Estado seguro y compartido

---

## 🚨 Troubleshooting

### Error: "Error acquiring the state lock"

**Causa:** Otro proceso tiene el lock o quedó bloqueado.

**Solución:**
```bash
# Forzar liberación del lock (¡CUIDADO!)
terraform force-unlock <LOCK_ID>
```

### Error: "Failed to get existing workspaces"

**Causa:** Permisos insuficientes en Storage Account.

**Solución:**
```bash
# Dar permisos al usuario
az role assignment create \
  --assignee <tu-email> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-terraform-state
```

### Estado local y remoto desincronizados

**Solución:**
```bash
# Eliminar estado local
rm terraform.tfstate*

# Re-inicializar
terraform init -reconfigure
```

---

## 📈 Mejoras Futuras

### Nivel Avanzado

1. **Workspaces de Terraform**
   ```bash
   terraform workspace new dev
   terraform workspace new prod
   ```

2. **Backends separados por ambiente**
   ```hcl
   key = "${var.environment}/terraform.tfstate"
   ```

3. **Políticas de Azure Policy**
   - Validar tags obligatorios
   - Restringir regiones
   - Limitar tamaños de VM

4. **Terraform Cloud**
   - UI para gestión de estado
   - Ejecución remota
   - Políticas como código (Sentinel)

---

## ✅ Checklist de Completado

- [x] Storage Account creado para estado
- [x] Backend remoto configurado
- [x] Locking funcionando
- [x] Ambientes dev/prod separados
- [x] NSG restringido a IP específica
- [x] Estado migrado de local a remoto
- [x] `.gitignore` actualizado
- [x] Documentación completa

---

## 🎯 Resultado Final

**Antes:**
- Estado local en tu máquina
- NSG abierto a todo el mundo
- Sin separación de ambientes
- No apto para trabajo en equipo

**Después:**
- ✅ Estado remoto en Azure Storage
- ✅ Locking automático
- ✅ NSG seguro (solo tu IP)
- ✅ Ambientes dev/prod separados
- ✅ Listo para trabajo en equipo
- ✅ **Nivel entrevista profesional**

---

## 📚 Recursos Adicionales

- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
- [Azure Storage State Locking](https://docs.microsoft.com/azure/developer/terraform/store-state-in-azure-storage)
- [Terraform Workspaces](https://www.terraform.io/docs/language/state/workspaces.html)
- [Best Practices for Terraform](https://www.terraform-best-practices.com/)

---

**🎉 ¡Felicitaciones! Ahora tienes Terraform a nivel profesional**

*Siguiente paso: [FASE 12 - CI/CD Profesional](fase12-cicd-profesional.md)*
