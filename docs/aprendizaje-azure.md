# 📘 Documentación de Aprendizaje - Azure DevOps

> Registro completo de comandos, teoría y análisis de mi proceso de aprendizaje en Azure

---

## 🎯 Sesión 1 - Fundamentos de Azure (21 Feb 2026)

### Objetivo de hoy
Crear la primera infraestructura en Azure manualmente para entender los conceptos base.

---

## 🔧 PASO 1: Instalación de Azure CLI

### ¿Qué es Azure CLI?
Herramienta de línea de comandos para gestionar recursos de Azure.

**Equivalencia AWS:** AWS CLI

### Comando de instalación (Linux)
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Verificación
```bash
az --version
```

**Resultado:**
```
azure-cli: 2.83.0
```

✅ **Instalación exitosa**

---

## 🔐 PASO 2: Autenticación en Azure

### Comando
```bash
az login
```

### ¿Qué hace?
- Abre el navegador para autenticación OAuth
- Conecta la CLI con tu cuenta de Azure
- Lista las suscripciones disponibles

### Conceptos clave

**Tenant (Inquilino):**
- Instancia de Azure Active Directory
- Representa una organización
- Puede tener múltiples suscripciones

**Subscription (Suscripción):**
- Contenedor de facturación
- Límite de recursos y permisos
- Equivalente a una "cuenta" en AWS

### Mi configuración
- **Tenant:** Directorio predeterminado
- **Subscription:** Azure subscription 1
- **ID:** 22f6f412-238f-495f-bcb8-d9e046b6b7a8

✅ **Autenticación exitosa**

---

## 🏗️ PASO 3: Resource Group

### ¿Qué es un Resource Group?
Contenedor lógico que agrupa recursos relacionados de Azure.

**🔄 Diferencia con AWS:**
- En AWS no existe este concepto
- Los recursos están "sueltos" y se agrupan con tags
- En Azure es OBLIGATORIO - todo recurso debe estar en un Resource Group

### Ventajas
- Gestión centralizada de recursos
- Eliminación en bloque (borras el RG = borras todo)
- Control de acceso por grupo
- Facturación agrupada

### Comando ejecutado
```bash
az group create --name rg-aprendizaje --location eastus
```

### Parámetros
- `--name`: Nombre del Resource Group
  - Convención: `rg-` + descripción
- `--location`: Región de Azure
  - `eastus` = East US (Virginia)
  - Equivalente a `us-east-1` en AWS

### Resultado
```json
{
  "id": "/subscriptions/22f6f412-238f-495f-bcb8-d9e046b6b7a8/resourceGroups/rg-aprendizaje",
  "location": "eastus",
  "name": "rg-aprendizaje",
  "properties": {
    "provisioningState": "Succeeded"
  }
}
```

✅ **Resource Group creado exitosamente**

---

## 🌐 PASO 4: Virtual Network (VNet)

### ¿Qué es una VNet?
Red virtual privada en Azure. Aísla y segmenta recursos.

**🔄 Equivalencia AWS:** VPC (Virtual Private Cloud)

### Conceptos clave

**Address Space (Espacio de direcciones):**
- Rango CIDR de la VNet completa
- Define cuántas IPs tendrás disponibles
- Ejemplo: `10.0.0.0/16` = 65,536 IPs

**Subnet (Subred):**
- Segmento dentro de la VNet
- Permite organizar recursos por capas (web, app, db)
- Ejemplo: `10.0.1.0/24` = 256 IPs

### Comando ejecutado
```bash
az network vnet create \
  --resource-group rg-aprendizaje \
  --name vnet-aprendizaje \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-principal \
  --subnet-prefix 10.0.1.0/24
```

### Parámetros explicados
- `--resource-group`: RG donde se crea (rg-aprendizaje)
- `--name`: Nombre de la VNet
- `--address-prefix`: Rango CIDR de la VNet (10.0.0.0/16)
- `--subnet-name`: Nombre de la primera subnet
- `--subnet-prefix`: Rango de la subnet (10.0.1.0/24)

### Arquitectura creada
```
VNet: 10.0.0.0/16 (65,536 IPs)
  └── Subnet: 10.0.1.0/24 (256 IPs)
```

### Nota importante
```
Resource provider 'Microsoft.Network' used by this operation is not registered. 
We are registering for you.
Registration succeeded.
```

**¿Qué significa?**
- Azure usa "Resource Providers" para cada servicio
- La primera vez que usas un servicio, se registra automáticamente
- Es normal y no indica error

### Resultado
```json
{
  "newVNet": {
    "addressSpace": {
      "addressPrefixes": ["10.0.0.0/16"]
    },
    "provisioningState": "Succeeded",
    "subnets": [
      {
        "addressPrefix": "10.0.1.0/24",
        "name": "subnet-principal",
        "provisioningState": "Succeeded"
      }
    ]
  }
}
```

✅ **VNet y Subnet creadas exitosamente**

---

## 📊 Resumen de infraestructura actual

```
Subscription: Azure subscription 1
  └── Resource Group: rg-aprendizaje (eastus)
        └── Virtual Network: vnet-aprendizaje (10.0.0.0/16)
              └── Subnet: subnet-principal (10.0.1.0/24)
```

---

## 🎓 Conceptos aprendidos hasta ahora

1. **Azure CLI** - Herramienta de gestión por terminal
2. **Tenant** - Organización en Azure AD
3. **Subscription** - Contenedor de facturación
4. **Resource Group** - Agrupación lógica de recursos (no existe en AWS)
5. **Virtual Network** - Red privada (= VPC en AWS)
6. **Subnet** - Segmento de red dentro de VNet
7. **Resource Provider** - Servicio de Azure que se registra automáticamente

---

## 🔄 Equivalencias AWS ↔ Azure (actualizado)

| Concepto | AWS | Azure |
|----------|-----|-------|
| CLI | AWS CLI | Azure CLI |
| Autenticación | `aws configure` | `az login` |
| Agrupación | Tags | Resource Groups |
| Red privada | VPC | Virtual Network (VNet) |
| Subred | Subnet | Subnet |
| Región | us-east-1 | eastus |

---

---

## 🔒 PASO 5: Network Security Group (NSG)

### ¿Qué es un NSG?
Firewall virtual que controla el tráfico de red (entrada y salida) a nivel de subnet o NIC.

**🔄 Equivalencia AWS:** Security Group

### Diferencias clave con AWS Security Groups

| Característica | AWS Security Group | Azure NSG |
|----------------|-------------------|----------|
| Nivel | Solo instancia | Subnet o NIC |
| Reglas deny | No (solo allow) | Sí (allow y deny) |
| Stateful | Sí | Sí |
| Prioridad | No aplica | Sí (100-4096) |

### Comando ejecutado (East US - primer intento)
```bash
az network nsg create \
  --resource-group rg-aprendizaje \
  --name nsg-vm-aprendizaje
```

### Reglas por defecto

Azure crea automáticamente reglas de seguridad por defecto:

**Inbound (Entrada):**
- Priority 65000: Permite tráfico desde VNet
- Priority 65001: Permite Azure Load Balancer
- Priority 65500: **Niega todo lo demás**

**Outbound (Salida):**
- Priority 65000: Permite tráfico a VNet
- Priority 65001: Permite salida a Internet
- Priority 65500: Niega todo lo demás

### Agregar regla SSH

```bash
az network nsg rule create \
  --resource-group rg-aprendizaje \
  --nsg-name nsg-vm-aprendizaje \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp
```

**Parámetros explicados:**
- `--priority`: Menor número = mayor prioridad (100-4096)
- `--source-address-prefixes '*'`: Desde cualquier IP
- `--destination-port-ranges 22`: Puerto SSH
- `--access Allow`: Permitir tráfico
- `--protocol Tcp`: Protocolo TCP

✅ **NSG y regla SSH creados**

---

## 🌐 PASO 6: IP Pública

### ¿Qué es?
Dirección IP pública para acceder a recursos desde Internet.

**🔄 Equivalencia AWS:** Elastic IP (EIP)

### Tipos de IP en Azure

**Basic SKU:**
- Asignación dinámica o estática
- No soporta zonas de disponibilidad
- Gratis cuando está asociada

**Standard SKU:**
- Siempre estática
- Soporta zonas de disponibilidad
- Más segura (cerrada por defecto)
- Tiene costo

### Comando ejecutado (East US)
```bash
az network public-ip create \
  --resource-group rg-aprendizaje \
  --name ip-publica-vm \
  --sku Standard \
  --allocation-method Static
```

**Resultado:** IP asignada: `20.85.232.116`

✅ **IP pública creada**

---

## 🔌 PASO 7: Network Interface (NIC)

### ¿Qué es?
Tarjeta de red virtual que conecta la VM a la VNet.

**🔄 Equivalencia AWS:** ENI (Elastic Network Interface)

### Conceptos clave

**Una NIC puede tener:**
- 1 IP privada (obligatoria)
- 1 IP pública (opcional)
- 1 NSG asociado
- Múltiples configuraciones IP

### Comando ejecutado (East US)
```bash
az network nic create \
  --resource-group rg-aprendizaje \
  --name nic-vm-aprendizaje \
  --vnet-name vnet-aprendizaje \
  --subnet subnet-principal \
  --public-ip-address ip-publica-vm \
  --network-security-group nsg-vm-aprendizaje
```

**Resultado:**
- IP privada asignada: `10.0.1.4`
- IP pública asociada: `20.85.232.116`
- NSG asociado: `nsg-vm-aprendizaje`

✅ **NIC creada y configurada**

---

## 🚨 LECCIÓN IMPORTANTE: Disponibilidad de SKUs

### El problema que enfrentamos

Al intentar crear la VM en **East US**, obtuvimos este error:

```
(SkuNotAvailable) The requested VM size for resource 'Standard_B1s' 
is currently not available in location 'eastus'.
```

### ¿Por qué pasa esto?

1. **Capacidad limitada:** Azure tiene capacidad física limitada por región
2. **Demanda alta:** Regiones populares se saturan
3. **SKUs específicos:** Algunos tamaños son más escasos
4. **Cuentas trial:** Tienen menor prioridad de asignación

### SKUs que intentamos en East US (todos fallaron)

❌ `Standard_B1s` - No disponible  
❌ `Standard_B2s` - No disponible  
❌ `Standard_D2s_v3` - No disponible  
❌ `Standard_D2s_v5` - No disponible  

### Solución: Cambiar de región

Decidimos recrear toda la infraestructura en **West US 2**.

### Lecciones aprendidas

1. **Siempre considera múltiples regiones** en diseño de arquitectura
2. **Usa zonas de disponibilidad** para alta disponibilidad
3. **Verifica disponibilidad** antes de desplegar en producción
4. **Ten plan B** con SKUs alternativos

**🔄 Equivalencia AWS:** En AWS pasa lo mismo con tipos de instancia en AZs específicas

---

## 🔄 RECREACIÓN EN WEST US 2

### Resource Group en nueva región

```bash
az group create \
  --name rg-aprendizaje-west \
  --location westus2
```

### VNet y Subnet

```bash
az network vnet create \
  --resource-group rg-aprendizaje-west \
  --name vnet-aprendizaje \
  --address-prefix 10.0.0.0/16 \
  --subnet-name subnet-principal \
  --subnet-prefix 10.0.1.0/24
```

### NSG

```bash
az network nsg create \
  --resource-group rg-aprendizaje-west \
  --name nsg-vm-aprendizaje
```

### Regla SSH

```bash
az network nsg rule create \
  --resource-group rg-aprendizaje-west \
  --nsg-name nsg-vm-aprendizaje \
  --name AllowSSH \
  --priority 1000 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22 \
  --access Allow \
  --protocol Tcp
```

### IP Pública

```bash
az network public-ip create \
  --resource-group rg-aprendizaje-west \
  --name ip-publica-vm \
  --sku Standard \
  --allocation-method Static
```

**Nueva IP asignada:** `20.114.13.52`

### NIC

```bash
az network nic create \
  --resource-group rg-aprendizaje-west \
  --name nic-vm-aprendizaje \
  --vnet-name vnet-aprendizaje \
  --subnet subnet-principal \
  --public-ip-address ip-publica-vm \
  --network-security-group nsg-vm-aprendizaje
```

**IP privada asignada:** `10.0.1.4`

---

## 🖥️ PASO 8: Virtual Machine (¡Por fin!)

### ¿Qué es?
Servidor virtual en la nube.

**🔄 Equivalencia AWS:** EC2 Instance

### Comando ejecutado (West US 2)

```bash
az vm create \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje \
  --nics nic-vm-aprendizaje \
  --image Ubuntu2204 \
  --size Standard_D2s_v5 \
  --admin-username azureuser \
  --generate-ssh-keys
```

### Parámetros explicados

- `--nics`: NIC previamente creada (con IP pública y NSG)
- `--image Ubuntu2204`: Ubuntu 22.04 LTS
- `--size Standard_D2s_v5`: 2 vCPU, 8GB RAM (serie D, generación 5)
- `--admin-username azureuser`: Usuario SSH
- `--generate-ssh-keys`: Genera claves SSH automáticamente en `~/.ssh/`

### Resultado

```json
{
  "powerState": "VM running",
  "publicIpAddress": "20.114.13.52",
  "privateIpAddress": "10.0.1.4",
  "macAddress": "7C-ED-8D-B6-B7-97"
}
```

✅ **VM creada y corriendo**

### Tamaños de VM en Azure

**Series principales:**

| Serie | Uso | Ejemplo |
|-------|-----|--------|
| B | Burstable (bajo costo) | B1s, B2s |
| D | Propósito general | D2s_v5, D4s_v5 |
| E | Optimizada para memoria | E4s_v5 |
| F | Optimizada para CPU | F4s_v5 |
| N | GPU | NC6s_v3 |

**Nomenclatura:**
- `Standard_D2s_v5`
  - `D` = Serie
  - `2` = Número de vCPUs
  - `s` = Soporta Premium Storage
  - `v5` = Generación 5

---

## 🔐 PASO 9: Conectar por SSH

### Comando

```bash
ssh azureuser@20.114.13.52
```

### ¿Qué pasa?

1. Azure CLI generó claves SSH en `~/.ssh/id_rsa` y `~/.ssh/id_rsa.pub`
2. La clave pública se instaló en la VM automáticamente
3. SSH usa la clave privada local para autenticarse
4. No necesitas contraseña

### Primera conexión

```
The authenticity of host '20.114.13.52' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Escribe `yes` y presiona Enter.

✅ **Conectado a la VM**

---

## 📦 PASO 10: Instalar Nginx

### Comandos (dentro de la VM)

```bash
sudo apt update
sudo apt install nginx -y
```

### Verificar estado

```bash
sudo systemctl status nginx
```

**Deberías ver:**
```
● nginx.service - A high performance web server
   Active: active (running)
```

### Salir de la VM

```bash
exit
```

✅ **Nginx instalado y corriendo**

---

## 🌐 PASO 11: Abrir puerto HTTP (80)

### ¿Por qué?

El NSG solo tiene abierto el puerto 22 (SSH). Necesitamos abrir el puerto 80 para HTTP.

### Comando (desde tu terminal local)

```bash
az network nsg rule create \
  --resource-group rg-aprendizaje-west \
  --nsg-name nsg-vm-aprendizaje \
  --name AllowHTTP \
  --priority 1001 \
  --source-address-prefixes '*' \
  --destination-port-ranges 80 \
  --access Allow \
  --protocol Tcp
```

**Nota:** Priority 1001 (después de SSH que es 1000)

✅ **Puerto 80 abierto**

---

## 🎯 PASO 12: Probar en el navegador

### URL

```
http://20.114.13.52
```

### Resultado esperado

```
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working.
```

✅ **¡FUNCIONA! Infraestructura completa desplegada**

---

## 📊 Arquitectura final desplegada

```
Azure Subscription
  └── Resource Group: rg-aprendizaje-west (westus2)
        ├── Virtual Network: vnet-aprendizaje (10.0.0.0/16)
        │     └── Subnet: subnet-principal (10.0.1.0/24)
        │
        ├── Network Security Group: nsg-vm-aprendizaje
        │     ├── Regla: AllowSSH (puerto 22, priority 1000)
        │     └── Regla: AllowHTTP (puerto 80, priority 1001)
        │
        ├── Public IP: ip-publica-vm (20.114.13.52)
        │
        ├── Network Interface: nic-vm-aprendizaje
        │     ├── IP privada: 10.0.1.4
        │     ├── IP pública: 20.114.13.52
        │     └── NSG: nsg-vm-aprendizaje
        │
        └── Virtual Machine: vm-aprendizaje
              ├── Tamaño: Standard_D2s_v5 (2 vCPU, 8GB RAM)
              ├── OS: Ubuntu 22.04 LTS
              ├── Usuario: azureuser
              └── Software: Nginx
```

---

## 🎓 Conceptos aprendidos - Resumen completo

### Infraestructura
1. **Resource Group** - Contenedor lógico (no existe en AWS)
2. **Virtual Network (VNet)** - Red privada (= VPC)
3. **Subnet** - Segmento de red
4. **Network Security Group (NSG)** - Firewall (= Security Group + Network ACL)
5. **Public IP** - IP pública estática (= Elastic IP)
6. **Network Interface (NIC)** - Tarjeta de red virtual (= ENI)
7. **Virtual Machine** - Servidor virtual (= EC2)

### Seguridad
1. **NSG Rules** - Reglas con prioridad (menor = mayor prioridad)
2. **SSH Keys** - Autenticación sin contraseña
3. **Inbound/Outbound rules** - Control de tráfico bidireccional

### Disponibilidad
1. **SKU Availability** - No todos los tamaños están disponibles en todas las regiones
2. **Multi-region** - Importancia de diseñar para múltiples regiones
3. **Capacity planning** - Verificar disponibilidad antes de desplegar

### Comandos Azure CLI
1. `az login` - Autenticación
2. `az group create` - Crear Resource Group
3. `az network vnet create` - Crear VNet
4. `az network nsg create` - Crear NSG
5. `az network nsg rule create` - Crear regla NSG
6. `az network public-ip create` - Crear IP pública
7. `az network nic create` - Crear NIC
8. `az vm create` - Crear VM

---

## 🔄 Equivalencias AWS ↔ Azure (actualizado completo)

| Concepto | AWS | Azure |
|----------|-----|-------|
| CLI | AWS CLI | Azure CLI |
| Autenticación | `aws configure` | `az login` |
| Agrupación | Tags | Resource Groups |
| Red privada | VPC | Virtual Network (VNet) |
| Subred | Subnet | Subnet |
| Firewall | Security Group + NACL | Network Security Group (NSG) |
| IP pública | Elastic IP | Public IP |
| Tarjeta red | ENI | Network Interface (NIC) |
| Servidor | EC2 | Virtual Machine |
| Región | us-east-1 | eastus |
| Zona disponibilidad | AZ (a, b, c) | Availability Zones (1, 2, 3) |
| Tamaño instancia | t2.micro, m5.large | Standard_B1s, Standard_D2s_v5 |

---

## 💰 Gestión de costos

### Recursos que generan costo

1. **Virtual Machine** - Por hora de ejecución
   - Standard_D2s_v5: ~$0.096/hora (~$70/mes)
2. **Public IP** - Standard SKU tiene costo
   - ~$0.005/hora (~$3.60/mes)
3. **Managed Disk** - Almacenamiento de la VM
   - ~$4-5/mes (30GB por defecto)

**Total estimado:** ~$78/mes si la dejas corriendo 24/7

### Cómo ahorrar

**Apagar la VM cuando no la uses:**
```bash
az vm deallocate \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

**Encender la VM:**
```bash
az vm start \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

**Eliminar todo cuando termines:**
```bash
az group delete \
  --name rg-aprendizaje-west \
  --yes --no-wait
```

⚠️ **Importante:** Eliminar el Resource Group borra TODOS los recursos dentro.

---

## ⏭️ Próximos pasos - Sesión 2

### Nivel básico
- [ ] Crear un disco adicional y montarlo
- [ ] Configurar backup de la VM
- [ ] Crear una imagen personalizada
- [ ] Implementar auto-shutdown

### Nivel intermedio
- [ ] Crear un Load Balancer
- [ ] Implementar VM Scale Set
- [ ] Configurar Azure Monitor y alertas
- [ ] Implementar Azure Bastion (SSH sin IP pública)

### Nivel avanzado
- [ ] Automatizar con Terraform
- [ ] Crear pipeline CI/CD con Azure DevOps
- [ ] Implementar contenedores con AKS
- [ ] Configurar VNet Peering

---

## 📝 Comandos útiles para gestión

### Ver estado de la VM
```bash
az vm get-instance-view \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje \
  --query instanceView.statuses[1] \
  --output table
```

### Listar todos los recursos del RG
```bash
az resource list \
  --resource-group rg-aprendizaje-west \
  --output table
```

### Ver IP pública
```bash
az network public-ip show \
  --resource-group rg-aprendizaje-west \
  --name ip-publica-vm \
  --query ipAddress \
  --output tsv
```

### Ver reglas del NSG
```bash
az network nsg rule list \
  --resource-group rg-aprendizaje-west \
  --nsg-name nsg-vm-aprendizaje \
  --output table
```

---

## 🎉 Logros de la Sesión 1

✅ Instalación y configuración de Azure CLI  
✅ Autenticación en Azure  
✅ Creación de Resource Group  
✅ Configuración de red completa (VNet + Subnet)  
✅ Implementación de seguridad (NSG + reglas)  
✅ Asignación de IP pública  
✅ Creación de Network Interface  
✅ Despliegue de Virtual Machine  
✅ Instalación de Nginx  
✅ Acceso por SSH  
✅ Servidor web funcionando públicamente  
✅ Lección importante sobre disponibilidad de SKUs  

**¡Primera infraestructura en Azure completada con éxito!** 🚀

---

**Última actualización:** 21 Feb 2026 - Sesión 1 completada ✅
