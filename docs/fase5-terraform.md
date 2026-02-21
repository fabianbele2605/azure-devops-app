# 📘 FASE 5 — Infraestructura como Código con Terraform

> Automatizar toda la infraestructura de Azure con código

---

## 🎯 Objetivo

Crear, modificar y destruir infraestructura completa de Azure usando código declarativo.

**Ventajas de IaC (Infrastructure as Code):**
- ✅ **Reproducible** - Crear/destruir en minutos
- ✅ **Versionado** - Infraestructura en Git
- ✅ **Documentado** - El código ES la documentación
- ✅ **Consistente** - Mismo resultado siempre
- ✅ **Colaborativo** - Múltiples personas trabajando
- ✅ **Auditable** - Historial de cambios

---

## 🔄 Comparación: Manual vs Terraform

### Antes (Manual con Azure CLI)

```bash
# 1. Resource Group
az group create --name rg-manual --location westus2

# 2. VNet
az network vnet create --resource-group rg-manual --name vnet-manual ...

# 3. Subnet
az network vnet subnet create --resource-group rg-manual ...

# 4. Public IP
az network public-ip create --resource-group rg-manual ...

# 5. NSG
az network nsg create --resource-group rg-manual ...

# 6. NSG Rules (3 comandos)
az network nsg rule create ...
az network nsg rule create ...
az network nsg rule create ...

# 7. NIC
az network nic create --resource-group rg-manual ...

# 8. VM
az vm create --resource-group rg-manual ...
```

**Problemas:**
- ⏱️ 30-40 minutos
- 😰 Propenso a errores
- 📝 Sin documentación automática
- ❌ Difícil de reproducir
- 🔄 No hay rollback fácil

---

### Ahora (Terraform)

```bash
terraform apply
```

**Ventajas:**
- ⏱️ 90 segundos
- ✅ Consistente y predecible
- 📝 Código autodocumentado
- ✅ Reproducible infinitas veces
- 🔄 Rollback con `terraform destroy`

---

## 📦 PASO 1: Instalación de Terraform

### Descargar e instalar

```bash
cd ~
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
sudo apt install unzip -y
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Verificar instalación

```bash
terraform version
```

**Output esperado:**
```
Terraform v1.7.0
```

✅ **Terraform instalado**

---

## 🏗️ PASO 2: Estructura del Proyecto

### Crear directorio

```bash
cd ~/fabian/DevOps/azureDevops
mkdir terraform
cd terraform
```

### Archivos de Terraform

Un proyecto Terraform típico tiene:

```
terraform/
├── provider.tf      # Configuración del proveedor (Azure)
├── variables.tf     # Variables de entrada
├── main.tf          # Recursos principales
├── outputs.tf       # Valores de salida
└── terraform.tfvars # Valores de variables (opcional)
```

---

## 📄 PASO 3: Archivos de Configuración

### 3.1 - provider.tf

**¿Qué hace?**
Define qué proveedor cloud usar (Azure, AWS, GCP, etc.)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

**Explicación:**
- `required_providers` - Especifica el provider de Azure
- `version = "~> 3.0"` - Usa versión 3.x (compatible)
- `features {}` - Configuración requerida por Azure provider

---

### 3.2 - variables.tf

**¿Qué hace?**
Define variables reutilizables con valores por defecto.

```hcl
variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-terraform-demo"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "westus2"
}

variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Usuario admin de la VM"
  type        = string
  default     = "azureuser"
}
```

**Ventajas:**
- Reutilización de valores
- Fácil cambiar configuración
- Validación de tipos
- Documentación integrada

---

### 3.3 - main.tf

**¿Qué hace?**
Define TODOS los recursos de infraestructura.

```hcl
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "subnet-principal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "ip-publica-terraform"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-terraform"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "App"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "nic-terraform"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                  = "vm-terraform"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
```

**Conceptos clave:**

**1. Recursos:**
```hcl
resource "TIPO" "NOMBRE_LOCAL" {
  # configuración
}
```

**2. Referencias entre recursos:**
```hcl
location = azurerm_resource_group.main.location
```
Terraform entiende las dependencias automáticamente.

**3. Variables:**
```hcl
name = var.resource_group_name
```

**4. Funciones:**
```hcl
public_key = file("~/.ssh/id_rsa.pub")
```

---

### 3.4 - outputs.tf

**¿Qué hace?**
Define qué valores mostrar después de `terraform apply`.

```hcl
output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "public_ip_address" {
  description = "IP pública de la VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = azurerm_linux_virtual_machine.main.name
}
```

**Útil para:**
- Ver información importante
- Pasar valores a otros sistemas
- Documentar la infraestructura

---

## 🚀 PASO 4: Workflow de Terraform

### 4.1 - Inicializar

```bash
terraform init
```

**¿Qué hace?**
- Descarga el provider de Azure
- Inicializa el backend (donde se guarda el estado)
- Prepara el directorio de trabajo

**Output:**
```
Initializing provider plugins...
- Installing hashicorp/azurerm v3.117.1...
Terraform has been successfully initialized!
```

✅ **Terraform inicializado**

---

### 4.2 - Planificar

```bash
terraform plan
```

**¿Qué hace?**
- Compara el estado actual con el deseado
- Muestra QUÉ va a crear/modificar/destruir
- NO ejecuta cambios (solo preview)

**Output:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

**Recursos a crear:**
1. azurerm_resource_group.main
2. azurerm_virtual_network.main
3. azurerm_subnet.main
4. azurerm_public_ip.main
5. azurerm_network_security_group.main
6. azurerm_network_interface.main
7. azurerm_network_interface_security_group_association.main
8. azurerm_linux_virtual_machine.main

---

### 4.3 - Aplicar

```bash
terraform apply
```

**¿Qué hace?**
- Ejecuta el plan
- Crea/modifica/destruye recursos
- Actualiza el estado

**Proceso:**
```
Do you want to perform these actions?
  Enter a value: yes

azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 16s
azurerm_public_ip.main: Creating...
azurerm_virtual_network.main: Creating...
azurerm_network_security_group.main: Creating...
...
azurerm_linux_virtual_machine.main: Creating...
azurerm_linux_virtual_machine.main: Creation complete after 53s

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:
public_ip_address = "52.247.192.109"
resource_group_name = "rg-terraform-demo"
vm_name = "vm-terraform"
```

**Tiempo total:** ~90 segundos

✅ **Infraestructura creada**

---

### 4.4 - Verificar estado

```bash
terraform show
```

Muestra el estado actual de todos los recursos.

```bash
terraform state list
```

Lista todos los recursos gestionados.

---

### 4.5 - Destruir

```bash
terraform destroy
```

**¿Qué hace?**
- Elimina TODOS los recursos creados
- En orden inverso de dependencias
- Limpia completamente

**Proceso:**
```
Do you really want to destroy all resources?
  Enter a value: yes

azurerm_network_interface_security_group_association.main: Destroying...
azurerm_linux_virtual_machine.main: Destroying...
azurerm_linux_virtual_machine.main: Destruction complete after 32s
azurerm_network_interface.main: Destroying...
azurerm_network_interface.main: Destruction complete after 12s
azurerm_subnet.main: Destroying...
azurerm_public_ip.main: Destroying...
azurerm_public_ip.main: Destruction complete after 11s
azurerm_subnet.main: Destruction complete after 12s
azurerm_virtual_network.main: Destroying...
azurerm_virtual_network.main: Destruction complete after 12s
azurerm_network_security_group.main: Destroying...
azurerm_network_security_group.main: Destruction complete after 6s
azurerm_resource_group.main: Destroying...
azurerm_resource_group.main: Destruction complete after 18s

Destroy complete! Resources: 8 destroyed.
```

**Tiempo total:** ~1 minuto

✅ **Todo eliminado limpiamente**

---

## 📊 Terraform State

### ¿Qué es el State?

Archivo que guarda el estado actual de la infraestructura.

**Ubicación:** `terraform.tfstate`

**Contiene:**
- IDs de recursos creados
- Configuración actual
- Metadatos

**⚠️ IMPORTANTE:**
- NO subir a Git (contiene información sensible)
- En producción, usar remote backend (Azure Storage, S3, etc.)

### .gitignore para Terraform

```
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
```

---

## 🎓 Conceptos Clave de Terraform

### 1. Declarativo vs Imperativo

**Imperativo (Azure CLI):**
```bash
# Dices CÓMO hacerlo paso a paso
az group create ...
az network vnet create ...
az network subnet create ...
```

**Declarativo (Terraform):**
```hcl
# Dices QUÉ quieres, Terraform decide cómo
resource "azurerm_resource_group" "main" {
  name     = "rg-demo"
  location = "westus2"
}
```

---

### 2. Idempotencia

Ejecutar `terraform apply` múltiples veces produce el mismo resultado.

```bash
terraform apply  # Crea recursos
terraform apply  # No hace nada (ya existen)
terraform apply  # Sigue sin hacer nada
```

---

### 3. Dependency Graph

Terraform entiende dependencias automáticamente:

```
Resource Group
    ↓
VNet ← NSG ← Public IP
    ↓
Subnet
    ↓
NIC (usa Subnet + Public IP + NSG)
    ↓
VM (usa NIC)
```

Crea en orden correcto y destruye en orden inverso.

---

### 4. Drift Detection

Terraform detecta cambios manuales:

```bash
# Alguien modifica algo manualmente en Azure Portal
terraform plan
# Terraform detecta la diferencia y puede corregirla
```

---

## 🔄 Workflow Completo

```
1. Escribir código Terraform
   ↓
2. terraform init (una vez)
   ↓
3. terraform plan (ver cambios)
   ↓
4. terraform apply (ejecutar)
   ↓
5. Usar infraestructura
   ↓
6. Modificar código si necesario
   ↓
7. terraform plan → apply (actualizar)
   ↓
8. terraform destroy (cuando termines)
```

---

## 💡 Mejores Prácticas

### 1. Usar variables

❌ **Malo:**
```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-hardcoded"
  location = "westus2"
}
```

✅ **Bueno:**
```hcl
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}
```

---

### 2. Usar outputs

```hcl
output "vm_ip" {
  value = azurerm_public_ip.main.ip_address
}
```

Facilita obtener información importante.

---

### 3. Modularizar

Para proyectos grandes, dividir en módulos:

```
terraform/
├── modules/
│   ├── network/
│   ├── compute/
│   └── security/
└── main.tf
```

---

### 4. Remote Backend

En producción, guardar state en Azure Storage:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

---

### 5. Workspaces

Para múltiples ambientes:

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

---

## 🆚 Terraform vs Otras Herramientas

| Herramienta | Tipo | Ventajas | Desventajas |
|-------------|------|----------|-------------|
| **Terraform** | IaC | Multi-cloud, gran comunidad | Curva de aprendizaje |
| **ARM Templates** | IaC | Nativo Azure | Solo Azure, complejo |
| **Bicep** | IaC | Nativo Azure, más simple | Solo Azure |
| **Pulumi** | IaC | Usa lenguajes reales (Python, JS) | Menos maduro |
| **Azure CLI** | Imperativo | Simple para tareas rápidas | No reproducible |

**Recomendación:** Terraform para multi-cloud, Bicep si solo usas Azure.

---

## 🎯 Casos de Uso Reales

### 1. Ambientes idénticos

```bash
# Desarrollo
terraform workspace select dev
terraform apply

# Producción
terraform workspace select prod
terraform apply
```

---

### 2. Disaster Recovery

```bash
# Región principal falla
terraform destroy  # Elimina región 1

# Cambiar variable de región
terraform apply    # Crea en región 2
```

---

### 3. Testing

```bash
terraform apply    # Crear ambiente de test
# Ejecutar tests
terraform destroy  # Limpiar
```

---

## 📚 Comandos Útiles

```bash
# Ver plan sin aplicar
terraform plan

# Aplicar sin confirmación
terraform apply -auto-approve

# Destruir sin confirmación
terraform destroy -auto-approve

# Ver estado actual
terraform show

# Listar recursos
terraform state list

# Ver un recurso específico
terraform state show azurerm_resource_group.main

# Formatear código
terraform fmt

# Validar sintaxis
terraform validate

# Ver outputs
terraform output

# Ver un output específico
terraform output public_ip_address
```

---

## 🐛 Troubleshooting

### Error: "Resource already exists"

**Solución:** Importar recurso existente
```bash
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-name
```

---

### Error: "State lock"

**Solución:** Forzar unlock
```bash
terraform force-unlock LOCK_ID
```

---

### Error: "Provider version conflict"

**Solución:** Actualizar providers
```bash
terraform init -upgrade
```

---

## 🎓 Conceptos Aprendidos

✅ **Infrastructure as Code (IaC)** - Infraestructura como código  
✅ **Declarativo** - Describes QUÉ quieres, no CÓMO  
✅ **Idempotencia** - Mismo resultado siempre  
✅ **State Management** - Terraform trackea el estado  
✅ **Dependency Graph** - Entiende dependencias automáticamente  
✅ **Plan → Apply → Destroy** - Workflow estándar  
✅ **Variables y Outputs** - Reutilización y documentación  
✅ **Multi-cloud** - Mismo lenguaje para AWS, Azure, GCP  

---

## 📊 Comparación Final

### Manual (FASE 2)
- ⏱️ Tiempo: 30-40 minutos
- 🔢 Comandos: ~15
- 😰 Errores: Frecuentes
- 📝 Documentación: Manual
- 🔄 Reproducible: No
- 💰 Costo: Tiempo humano

### Terraform (FASE 5)
- ⏱️ Tiempo: 90 segundos
- 🔢 Comandos: 1 (`terraform apply`)
- ✅ Errores: Mínimos
- 📝 Documentación: Automática (el código)
- 🔄 Reproducible: Sí, infinitas veces
- 💰 Costo: Casi cero

---

## ⏭️ Próximos pasos

### Nivel Intermedio
- [ ] Usar módulos de Terraform
- [ ] Implementar remote backend
- [ ] Crear múltiples ambientes con workspaces
- [ ] Integrar Terraform en CI/CD

### Nivel Avanzado
- [ ] Terraform Cloud
- [ ] Policy as Code (Sentinel)
- [ ] Terraform con Kubernetes
- [ ] Multi-cloud deployments

---

## 📚 Recursos adicionales

- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)

---

**Completado:** 21 Feb 2026 ✅

**Logros:**
- ✅ Terraform instalado y configurado
- ✅ Infraestructura completa en código
- ✅ Creación automatizada (90 segundos)
- ✅ Destrucción limpia (60 segundos)
- ✅ Código versionado en Git
- ✅ Reproducible infinitas veces

**¡Nivel IaC Profesional alcanzado!** 🚀
