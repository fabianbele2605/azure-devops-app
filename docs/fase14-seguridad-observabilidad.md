# FASE 14 - Seguridad y Observabilidad Avanzada

> **Semana 4 del Plan de Pulido:** Alertas con Prometheus/AlertManager + Azure Key Vault para Secrets Management

---

## 📋 Índice

1. [Objetivos](#objetivos)
2. [Conceptos Clave](#conceptos-clave)
3. [Arquitectura](#arquitectura)
4. [PARTE 1: Sistema de Alertas](#parte-1-sistema-de-alertas)
5. [PARTE 2: Azure Key Vault](#parte-2-azure-key-vault)
6. [Antes vs Después](#antes-vs-después)
7. [Preguntas de Entrevista](#preguntas-de-entrevista)
8. [Troubleshooting](#troubleshooting)
9. [Mejoras Futuras](#mejoras-futuras)
10. [Checklist](#checklist)

---

## 🎯 Objetivos

### PARTE 1: Sistema de Alertas
- Implementar **PrometheusRule** con alertas personalizadas
- Desplegar **AlertManager** para gestión de notificaciones
- Configurar alertas para pods caídos, CPU alta, memoria alta
- Integrar alertas con Prometheus Operator

### PARTE 2: Azure Key Vault
- Crear **Azure Key Vault** con Terraform
- Implementar **Managed Identity** en la VM
- Almacenar secrets de forma segura (passwords, API keys)
- Configurar **Access Policies** para control de acceso
- Probar acceso a secrets desde la VM

---

## 📚 Conceptos Clave

### Sistema de Alertas

#### PrometheusRule
- **CRD (Custom Resource Definition)** de Prometheus Operator
- Define reglas de alertas usando PromQL
- Se organiza en grupos con intervalos de evaluación
- Soporta labels y annotations para clasificación

#### AlertManager
- **Gestor centralizado de alertas** de Prometheus
- Agrupa, deduplica y enruta alertas
- Soporta múltiples receivers (email, Slack, PagerDuty)
- Implementa silencing e inhibition rules

#### PromQL (Prometheus Query Language)
- Lenguaje de consulta para métricas de Prometheus
- Soporta agregaciones, funciones matemáticas, operadores
- Ejemplos:
  - `up{job="miappdevops"} == 0` - Pod caído
  - `rate(cpu_usage[5m]) > 0.8` - CPU alta

#### ServiceMonitor
- CRD que define cómo Prometheus debe scrapear un servicio
- Usa selectores de labels para encontrar Services
- Configura endpoints, puertos, paths, intervalos

### Azure Key Vault

#### Managed Identity
- **Identidad gestionada por Azure** para recursos
- Elimina necesidad de credenciales hardcodeadas
- Tipos:
  - **System-assigned**: Ligada al ciclo de vida del recurso
  - **User-assigned**: Independiente, reutilizable

#### Access Policies
- **Control de acceso basado en permisos** (RBAC)
- Define qué identidades pueden acceder a qué recursos
- Permisos granulares: Get, List, Set, Delete, Purge, Recover

#### Secrets Management
- Almacenamiento seguro de información sensible
- Versionado automático de secrets
- Auditoría de accesos
- Rotación de secrets

---

## 🏗️ Arquitectura

### Sistema de Alertas

```
┌─────────────────────────────────────────────────────────┐
│                    Prometheus                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PrometheusRule (miappdevops-alerts)             │  │
│  │  - PodDown (critical)                            │  │
│  │  - InsufficientPods (warning)                    │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│                         ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Evaluación cada 30s                             │  │
│  │  - Ejecuta queries PromQL                        │  │
│  │  - Verifica condiciones "for: 1m"                │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│                         ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Alerta disparada → AlertManager                 │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  AlertManager                           │
│  - Agrupa alertas por severity                          │
│  - Deduplica alertas repetidas                          │
│  - Enruta a receivers (email, Slack)                    │
│  - Expuesto en NodePort 30093                           │
└─────────────────────────────────────────────────────────┘
```

### Azure Key Vault

```
┌─────────────────────────────────────────────────────────┐
│              Azure Key Vault (kv-devops-fb-dev)         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Secrets:                                        │  │
│  │  - db-password: MySecurePassword123!            │  │
│  │  - api-key: sk-1234567890abcdef                 │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Access Policies:                                │  │
│  │  1. Usuario: Get, List, Set, Delete, Purge      │  │
│  │  2. VM (Managed Identity): Get, List            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  VM (vm-terraform)                      │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Managed Identity (System-assigned)              │  │
│  │  Object ID: 6b3bd0f5-d7c3-4c47-be93-061f75ef0a20│  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  az login --identity --allow-no-subscriptions    │  │
│  │  az keyvault secret show --vault-name ...        │  │
│  │  → MySecurePassword123!                          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 PARTE 1: Sistema de Alertas

### Paso 1: Crear PrometheusRule

**Archivo:** `k8s/monitoring/prometheus-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: miappdevops-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
    release: prometheus  # ← CRÍTICO: Prometheus Operator busca este label
spec:
  groups:
  - name: application_alerts
    interval: 30s
    rules:
    - alert: PodDown
      expr: up{job="miappdevops-metrics"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pod está caído"
        description: "El pod no responde desde hace más de 1 minuto."
    
    - alert: InsufficientPods
      expr: count(up{job="miappdevops-metrics"} == 1) < 2
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "Menos de 2 pods activos"
        description: "Solo hay pocos pods activos."
```

**Conceptos:**
- `expr`: Query PromQL que evalúa la condición
- `for`: Tiempo que debe cumplirse antes de disparar
- `severity`: Clasificación (critical, warning, info)
- `annotations`: Mensajes descriptivos para la alerta

**Aplicar:**
```bash
kubectl apply -f k8s/monitoring/prometheus-rules.yaml
```

### Paso 2: Desplegar AlertManager

**Archivo:** `k8s/monitoring/alertmanager.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m

    route:
      group_by: ['alertname', 'severity']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'email-notifications'

    receivers:
    - name: 'email-notifications'
      email_configs:
      - to: 'devops@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'

    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'instance']

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v0.26.0
        args:
          - '--config.file=/etc/alertmanager/alertmanager.yml'
        ports:
        - containerPort: 9093
        volumeMounts:
        - name: config
          mountPath: /etc/alertmanager
      volumes:
      - name: config
        configMap:
          name: alertmanager-config

---
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - port: 9093
    targetPort: 9093
    nodePort: 30093
  selector:
    app: alertmanager
```

**Aplicar:**
```bash
kubectl apply -f k8s/monitoring/alertmanager.yaml
```

### Paso 3: Abrir puerto en NSG

```bash
az network nsg rule create \
  --resource-group rg-terraform-demo \
  --nsg-name nsg-terraform \
  --name AllowAlertManager \
  --priority 1006 \
  --source-address-prefixes 190.84.117.210/32 \
  --destination-port-ranges 30093 \
  --access Allow \
  --protocol Tcp \
  --direction Inbound
```

### Paso 4: Verificar

```bash
# Ver PrometheusRule
kubectl get prometheusrule -n monitoring

# Ver pods
kubectl get pods -n monitoring | grep alertmanager

# Ver services
kubectl get svc -n monitoring | grep alertmanager

# Acceder a AlertManager
# http://40.65.92.138:30093

# Ver reglas en Prometheus
# http://40.65.92.138:30090/rules
# Buscar "application_alerts"

# Ver targets
# http://40.65.92.138:30090/targets
# Buscar "miappdevops-metrics"
```

### Troubleshooting Común

#### Problema: PrometheusRule no aparece en Prometheus

**Causa:** Falta el label `release: prometheus`

**Solución:**
```bash
# Verificar qué labels busca Prometheus
kubectl get prometheus prometheus-kube-prometheus-prometheus -n monitoring -o yaml | grep -A 3 ruleSelector

# Debe mostrar:
# ruleSelector:
#   matchLabels:
#     release: prometheus
```

#### Problema: ServiceMonitor no encuentra pods

**Causa:** Service no tiene endpoints

**Solución:**
```bash
# Verificar endpoints
kubectl get endpoints miappdevops-metrics

# Si está vacío, verificar:
# 1. Pods tienen el label correcto
kubectl get pods --show-labels | grep miappdevops

# 2. Service selector coincide con pod labels
kubectl get svc miappdevops-metrics -o yaml | grep -A 3 selector
```

---

## 🔐 PARTE 2: Azure Key Vault

### Paso 1: Crear Key Vault con Terraform

**Archivo:** `terraform/keyvault.tf`

```hcl
# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-devops-fb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Access Policy para el usuario actual
resource "azurerm_key_vault_access_policy" "user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Access Policy para la VM (Managed Identity)
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.main.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# Secrets de ejemplo
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.user]
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  value        = var.api_key
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.user]
}

data "azurerm_client_config" "current" {}
```

**Archivo:** `terraform/variables.tf` (agregar)

```hcl
variable "db_password" {
  description   = "Database password"
  type          = string
  sensitive     = true
  default       = "MySecurePassword123!"
}

variable "api_key" {
  description   = "API Key for external services"
  type          = string
  sensitive     = true
  default       = "sk-1234567890abcdef"
}
```

**Archivo:** `terraform/main.tf` (actualizar VM)

```hcl
resource "azurerm_linux_virtual_machine" "main" {
  # ... configuración existente ...

  # Agregar Managed Identity
  identity {
    type = "SystemAssigned"
  }
}
```

### Paso 2: Aplicar Terraform

```bash
cd terraform

# Renombrar aks.tf para evitar crear AKS
mv aks.tf aks.tf.bak

# Aplicar cambios
terraform init
terraform plan
terraform apply

# Ver outputs
terraform output key_vault_name
terraform output key_vault_uri
```

### Paso 3: Verificar Secrets

```bash
# Listar secrets
az keyvault secret list --vault-name kv-devops-fb-dev --output table

# Ver valor de un secret
az keyvault secret show \
  --vault-name kv-devops-fb-dev \
  --name db-password \
  --query value -o tsv
```

### Paso 4: Probar desde la VM

```bash
# Conectar a la VM
ssh azureuser@40.65.92.138

# Instalar Azure CLI (si no está)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login con Managed Identity
az login --identity --allow-no-subscriptions

# Leer secret
az keyvault secret show \
  --vault-name kv-devops-fb-dev \
  --name db-password \
  --query value -o tsv

# Resultado: MySecurePassword123!
```

### Conceptos Importantes

#### ¿Por qué Managed Identity?
- **Sin credenciales hardcodeadas** en código o configuración
- **Rotación automática** de credenciales por Azure
- **Auditoría integrada** de accesos
- **Principio de menor privilegio** (solo Get/List)

#### ¿Por qué Access Policies?
- **Control granular** de permisos
- **Separación de responsabilidades** (usuario vs VM)
- **Auditoría** de quién accede a qué
- **Revocación fácil** de permisos

#### Soft Delete
- Secrets eliminados se mantienen **90 días** por defecto
- Protección contra eliminación accidental
- Recuperación con `az keyvault secret recover`
- Purga permanente con `az keyvault secret purge`

---

## 📊 Antes vs Después

### Sistema de Alertas

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Alertas** | Solo alertas predefinidas de Prometheus Operator | Alertas personalizadas para tu aplicación |
| **Notificaciones** | No configuradas | AlertManager con routing y grouping |
| **Visibilidad** | Solo métricas en Grafana | Alertas proactivas + métricas |
| **Gestión** | Manual, reactiva | Automatizada, proactiva |
| **Acceso** | Solo Prometheus (30090) | Prometheus + AlertManager (30093) |

### Azure Key Vault

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Secrets** | Hardcodeados en código/config | Almacenados en Key Vault |
| **Acceso** | Credenciales en archivos | Managed Identity sin credenciales |
| **Seguridad** | Riesgo de exposición | Cifrado, auditoría, control de acceso |
| **Rotación** | Manual, propensa a errores | Automatizable, versionado |
| **Auditoría** | No disponible | Logs de acceso completos |
| **IaC** | No gestionado | Terraform con state remoto |

---

## 🎓 Preguntas de Entrevista

### Sistema de Alertas

**P: ¿Qué es PrometheusRule y cómo funciona?**

R: PrometheusRule es un CRD (Custom Resource Definition) de Prometheus Operator que define reglas de alertas usando PromQL. Prometheus evalúa estas reglas periódicamente (cada 30s por defecto) y si la condición se cumple durante el tiempo especificado en `for`, dispara la alerta a AlertManager.

**P: ¿Cuál es la diferencia entre `for: 1m` y evaluar directamente?**

R: `for: 1m` significa que la condición debe cumplirse continuamente durante 1 minuto antes de disparar la alerta. Esto evita alertas por picos momentáneos (flapping). Sin `for`, la alerta se dispara inmediatamente.

**P: ¿Qué hace AlertManager?**

R: AlertManager gestiona alertas de Prometheus:
- **Agrupa** alertas similares (por severity, alertname)
- **Deduplica** alertas repetidas
- **Enruta** a diferentes receivers (email, Slack, PagerDuty)
- **Silencia** alertas temporalmente
- **Inhibe** alertas de menor prioridad cuando hay críticas

**P: ¿Por qué el ServiceMonitor no encontraba los pods?**

R: Tres causas comunes:
1. **Service sin endpoints**: Los pods no tienen el label que busca el Service
2. **Namespace incorrecto**: ServiceMonitor busca en namespace específico
3. **Label faltante**: ServiceMonitor necesita `release: prometheus` para que Prometheus Operator lo detecte

**P: ¿Qué es el job en Prometheus?**

R: El `job` es un label que Prometheus asigna a las métricas scrapeadas. Se define en el ServiceMonitor y agrupa todos los targets de un mismo servicio. En nuestro caso: `job="miappdevops-metrics"`.

### Azure Key Vault

**P: ¿Qué es Managed Identity y cuáles son sus ventajas?**

R: Managed Identity es una identidad gestionada por Azure para recursos (VMs, App Services, etc.). Ventajas:
- **Sin credenciales**: No hay passwords/keys que gestionar
- **Rotación automática**: Azure rota las credenciales automáticamente
- **Integración nativa**: Funciona con todos los servicios de Azure
- **Auditoría**: Todos los accesos quedan registrados
- **Principio de menor privilegio**: Permisos granulares

**P: ¿Cuál es la diferencia entre System-assigned y User-assigned Managed Identity?**

R:
- **System-assigned**: Ligada al ciclo de vida del recurso. Se crea/elimina con el recurso. Una identidad por recurso.
- **User-assigned**: Independiente, puede compartirse entre múltiples recursos. Persiste aunque se elimine el recurso.

**P: ¿Qué son Access Policies en Key Vault?**

R: Access Policies definen qué identidades (usuarios, service principals, managed identities) pueden realizar qué operaciones (Get, List, Set, Delete, Purge, Recover) sobre qué recursos (secrets, keys, certificates) en el Key Vault.

**P: ¿Por qué usar `depends_on` en los secrets?**

R: Para asegurar que el Access Policy del usuario se cree antes que los secrets. Sin el Access Policy, Terraform no tendría permisos para crear los secrets y fallaría.

**P: ¿Qué es soft delete y por qué es importante?**

R: Soft delete mantiene los secrets eliminados durante 90 días (por defecto) antes de purgarlos permanentemente. Protege contra:
- Eliminación accidental
- Eliminación maliciosa
- Permite recuperación con `az keyvault secret recover`

**P: ¿Cómo se integraría Key Vault con Kubernetes?**

R: Usando el **Secrets Store CSI Driver**:
1. Instalar el driver en el cluster
2. Crear un SecretProviderClass que apunte al Key Vault
3. Montar secrets como volúmenes en pods
4. Los secrets se sincronizan automáticamente

---

## 🔧 Troubleshooting

### Alertas no aparecen en Prometheus

**Síntoma:** PrometheusRule creado pero no aparece en `/rules`

**Diagnóstico:**
```bash
# 1. Verificar que existe
kubectl get prometheusrule miappdevops-alerts -n monitoring

# 2. Ver labels
kubectl get prometheusrule miappdevops-alerts -n monitoring -o yaml | grep -A 5 labels

# 3. Ver qué labels busca Prometheus
kubectl get prometheus prometheus-kube-prometheus-prometheus -n monitoring -o yaml | grep -A 3 ruleSelector
```

**Solución:** Agregar label `release: prometheus`

### ServiceMonitor sin targets

**Síntoma:** ServiceMonitor existe pero no aparece en `/targets`

**Diagnóstico:**
```bash
# 1. Verificar Service
kubectl get svc miappdevops-metrics

# 2. Verificar endpoints
kubectl get endpoints miappdevops-metrics

# 3. Verificar pods con labels
kubectl get pods --show-labels | grep miappdevops

# 4. Verificar selector del Service
kubectl get svc miappdevops-metrics -o yaml | grep -A 3 selector
```

**Solución:** Asegurar que pods tienen label `app: miappdevops`

### Key Vault "VaultAlreadyExists"

**Síntoma:** Error al crear Key Vault con nombre duplicado

**Diagnóstico:**
```bash
# Verificar si existe en soft-delete
az keyvault list-deleted --query "[?name=='kv-devops-dev']"
```

**Solución:**
```bash
# Opción 1: Purgar el vault eliminado
az keyvault purge --name kv-devops-dev

# Opción 2: Usar nombre único
# En keyvault.tf: name = "kv-devops-fb-${var.environment}"
```

### VM no puede leer secrets

**Síntoma:** `az keyvault secret show` falla con "Forbidden"

**Diagnóstico:**
```bash
# 1. Verificar Managed Identity
az vm identity show --name vm-terraform --resource-group rg-terraform-demo

# 2. Verificar Access Policy
az keyvault show --name kv-devops-fb-dev --query properties.accessPolicies
```

**Solución:**
```bash
# Aplicar Access Policy con Terraform
terraform apply

# O manualmente
az keyvault set-policy \
  --name kv-devops-fb-dev \
  --object-id <MANAGED_IDENTITY_OBJECT_ID> \
  --secret-permissions get list
```

---

## 🚀 Mejoras Futuras

### Sistema de Alertas

1. **Agregar más alertas**
   - Latencia de requests (P95, P99)
   - Tasa de errores HTTP 4xx/5xx
   - Uso de disco
   - Reinicio frecuente de pods

2. **Configurar receivers reales**
   - Slack webhook
   - Email con SMTP real
   - PagerDuty para on-call

3. **Implementar silencing**
   - Silenciar durante mantenimientos
   - Silenciar alertas conocidas temporalmente

4. **Agregar métricas custom**
   - Instrumentar aplicación .NET con Prometheus client
   - Exponer métricas de negocio (usuarios activos, transacciones)

### Azure Key Vault

1. **Integrar con Kubernetes**
   - Instalar Secrets Store CSI Driver
   - Crear SecretProviderClass
   - Montar secrets en pods

2. **Rotación automática**
   - Configurar rotación de secrets
   - Implementar webhooks para notificaciones

3. **Secrets adicionales**
   - Certificados SSL/TLS
   - Connection strings de bases de datos
   - API keys de servicios externos

4. **Auditoría avanzada**
   - Enviar logs a Log Analytics
   - Crear alertas de accesos sospechosos
   - Dashboard de auditoría en Grafana

---

## ✅ Checklist

### PARTE 1: Sistema de Alertas

- [ ] PrometheusRule creado con label `release: prometheus`
- [ ] AlertManager desplegado en namespace `monitoring`
- [ ] Service de AlertManager con NodePort 30093
- [ ] Puerto 30093 abierto en NSG de Azure
- [ ] AlertManager accesible en http://IP:30093
- [ ] Reglas visibles en Prometheus /rules
- [ ] ServiceMonitor detectando pods (2/2 targets up)
- [ ] Alertas evaluándose cada 30s

### PARTE 2: Azure Key Vault

- [ ] Key Vault creado con Terraform (`kv-devops-fb-dev`)
- [ ] Managed Identity agregada a la VM
- [ ] Access Policy para usuario configurada
- [ ] Access Policy para VM configurada
- [ ] Secrets `db-password` y `api-key` creados
- [ ] Secrets visibles con `az keyvault secret list`
- [ ] VM puede leer secrets con Managed Identity
- [ ] Terraform state actualizado

### Documentación

- [ ] README.md actualizado con FASE 14
- [ ] Archivos de configuración commiteados
- [ ] Documentación de troubleshooting completa
- [ ] Preguntas de entrevista documentadas

---

## 📈 Métricas del Proyecto

**Después de FASE 14:**
- **Líneas de código:** ~5000+
- **Archivos de documentación:** 11
- **Recursos de Azure:** 9 (+ Key Vault)
- **Pods en Kubernetes:** 20 (+ AlertManager)
- **Alertas configuradas:** 2 (PodDown, InsufficientPods)
- **Secrets gestionados:** 2 (db-password, api-key)
- **Fases completadas:** 14/14 🎉

---

## 🎊 Conclusión

Has completado la **FASE 14 - Seguridad y Observabilidad Avanzada**, implementando:

✅ **Sistema de Alertas** con Prometheus y AlertManager
✅ **Azure Key Vault** para gestión segura de secrets
✅ **Managed Identity** sin credenciales hardcodeadas
✅ **Access Policies** con control granular
✅ **Integración completa** con infraestructura existente

**Plan de Pulido completado: 4/4 semanas** 🎉

---

*Última actualización: 22 Feb 2026*
