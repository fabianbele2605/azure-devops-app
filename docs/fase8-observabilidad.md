# 📊 FASE 8 - Observabilidad (Monitoring & Logging)

> Implementación de stack completo de observabilidad con Prometheus, Grafana y métricas de aplicación

---

## 📋 Objetivos

- ✅ Instalar Prometheus para recolección de métricas
- ✅ Configurar Grafana para visualización
- ✅ Exponer métricas de aplicación .NET
- ✅ Crear dashboards personalizados
- ✅ Configurar ServiceMonitor para auto-discovery

---

## 🛠️ Herramientas Utilizadas

- **Prometheus**: Sistema de monitoreo y base de datos de series temporales
- **Grafana**: Plataforma de visualización y análisis
- **Helm**: Gestor de paquetes para Kubernetes
- **prometheus-net**: Librería de métricas para .NET
- **kube-prometheus-stack**: Stack completo de monitoreo

---

## 📦 1. Instalación de Helm

Helm es el gestor de paquetes de Kubernetes que facilita la instalación de aplicaciones complejas.

### Instalación en VM

```bash
# Conectar a VM
ssh -i ~/.ssh/id_rsa azureuser@40.65.92.138

# Instalar Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verificar instalación
helm version
# Output: version.BuildInfo{Version:"v3.20.0"...}
```

---

## 📊 2. Instalación de kube-prometheus-stack

Este stack incluye Prometheus, Grafana, Alertmanager, y múltiples exporters.

### Agregar Repositorio

```bash
# Agregar repositorio de Prometheus Community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Actualizar repositorios
helm repo update
```

### Crear Namespace

```bash
# Crear namespace para monitoring
sudo kubectl create namespace monitoring
```

### Instalar Stack

```bash
# Instalar con configuración personalizada
sudo -E helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30030 \
  --set grafana.adminPassword=admin123
```

**Parámetros importantes:**
- `prometheus.service.type=NodePort`: Expone Prometheus externamente
- `prometheus.service.nodePort=30090`: Puerto para Prometheus
- `grafana.service.type=NodePort`: Expone Grafana externamente
- `grafana.service.nodePort=30030`: Puerto para Grafana
- `grafana.adminPassword=admin123`: Password de admin

### Verificar Instalación

```bash
# Ver pods (esperar ~2 minutos)
sudo kubectl get pods -n monitoring

# Output esperado:
# NAME                                                     READY   STATUS    RESTARTS   AGE
# alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m
# prometheus-grafana-xxx                                   3/3     Running   0          2m
# prometheus-kube-prometheus-operator-xxx                  1/1     Running   0          2m
# prometheus-kube-state-metrics-xxx                        1/1     Running   0          2m
# prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          2m
# prometheus-prometheus-node-exporter-xxx                  1/1     Running   0          2m

# Ver servicios
sudo kubectl get svc -n monitoring

# Output esperado:
# NAME                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# prometheus-grafana                        NodePort    10.43.154.63    <none>        80:30030/TCP
# prometheus-kube-prometheus-prometheus     NodePort    10.43.64.239    <none>        9090:30090/TCP
```

---

## 🔓 3. Abrir Puertos en Azure NSG

Para acceder a Grafana y Prometheus desde el navegador:

```bash
# En tu PC local (no en la VM)

# Abrir puerto 30030 para Grafana
az network nsg rule create \
  --resource-group rg-terraform-demo \
  --nsg-name nsg-terraform \
  --name AllowGrafana \
  --priority 1004 \
  --source-address-prefixes '*' \
  --destination-port-ranges 30030 \
  --access Allow \
  --protocol Tcp

# Abrir puerto 30090 para Prometheus
az network nsg rule create \
  --resource-group rg-terraform-demo \
  --nsg-name nsg-terraform \
  --name AllowPrometheus \
  --priority 1005 \
  --source-address-prefixes '*' \
  --destination-port-ranges 30090 \
  --access Allow \
  --protocol Tcp
```

---

## 🎯 4. Configurar Métricas en Aplicación .NET

### Agregar Paquete NuGet

Editar `app/MiAppDevOps.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="prometheus-net.AspNetCore" Version="8.2.1" />
  </ItemGroup>
</Project>
```

### Configurar Middleware

Editar `app/Program.cs`:

```csharp
using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// Exponer métricas de Prometheus
app.UseHttpMetrics();

app.UseAuthorization();

app.MapRazorPages();

// Endpoint de métricas
app.MapMetrics();

app.Run();
```

**Características:**
- `UseHttpMetrics()`: Captura métricas HTTP automáticamente
- `MapMetrics()`: Expone endpoint `/metrics`

### Métricas Disponibles

Una vez configurado, la aplicación expone:

- `http_request_duration_seconds`: Latencia de requests
- `http_requests_received_total`: Total de requests
- `http_requests_in_progress`: Requests en progreso
- `process_cpu_seconds_total`: Uso de CPU
- `process_working_set_bytes`: Memoria utilizada
- `dotnet_collection_count_total`: Colecciones de GC
- `dotnet_total_memory_bytes`: Memoria total .NET

### Probar Localmente

```bash
cd app
dotnet restore
dotnet run

# En otra terminal
curl http://localhost:5016/metrics
```

---

## 🔄 5. Rebuild y Deploy de Aplicación

### Build Nueva Imagen

```bash
cd ~/fabian/DevOps/azureDevops/app

# Build con métricas
docker build -t miappdevops:latest .

# Guardar y transferir
docker save miappdevops:latest | gzip > miappdevops-metrics.tar.gz
scp -i ~/.ssh/id_rsa miappdevops-metrics.tar.gz azureuser@40.65.92.138:/home/azureuser/
```

### Deploy en K3s

```bash
# Conectar a VM
ssh -i ~/.ssh/id_rsa azureuser@40.65.92.138

# Importar imagen
sudo k3s ctr images import miappdevops-metrics.tar.gz

# Verificar
sudo k3s ctr images ls | grep miappdevops

# Reiniciar deployment
sudo kubectl rollout restart deployment miappdevops

# Verificar pods
sudo kubectl get pods -w
```

### Verificar Métricas

```bash
# Port-forward para probar
POD=$(sudo kubectl get pod -l app=miappdevops -o jsonpath='{.items[0].metadata.name}')
sudo kubectl port-forward $POD 8080:5000 &

# Verificar métricas
curl localhost:8080/metrics | head -30

# Matar port-forward
sudo pkill -f "port-forward"
```

---

## 🎯 6. Configurar ServiceMonitor

ServiceMonitor es un CRD (Custom Resource Definition) que le dice a Prometheus qué servicios monitorear.

### Crear Service y ServiceMonitor

```bash
# En la VM
sudo kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: miappdevops-metrics
  labels:
    app: miappdevops
spec:
  selector:
    app: miappdevops
  ports:
  - name: metrics
    port: 5000
    targetPort: 5000
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: miappdevops-monitor
  labels:
    app: miappdevops
    release: prometheus
spec:
  selector:
    matchLabels:
      app: miappdevops
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
EOF
```

**Componentes:**

**Service:**
- Expone los pods de la aplicación internamente
- Puerto 5000 para métricas

**ServiceMonitor:**
- `release: prometheus`: Label requerido para que Prometheus lo detecte
- `interval: 30s`: Frecuencia de scraping
- `path: /metrics`: Endpoint de métricas

### Verificar

```bash
# Ver ServiceMonitor
sudo kubectl get servicemonitor

# Ver si Prometheus lo detectó
# Ir a http://40.65.92.138:30090
# Status → Targets → Buscar "miappdevops-monitor"
```

---

## 🎨 7. Acceder a Grafana

### URL y Credenciales

- **URL:** http://40.65.92.138:30030
- **Usuario:** `admin`
- **Password:** `admin123`

### Primera Vez

1. Abre http://40.65.92.138:30030
2. Login con admin/admin123
3. Grafana te pedirá cambiar la password (puedes skip)

---

## 📈 8. Crear Dashboard en Grafana

### Explorar Métricas

1. **Click en el icono de brújula** (Explore) en el menú izquierdo
2. **Selecciona Prometheus** como data source
3. **Prueba queries:**
   ```promql
   http_requests_received_total
   ```
4. **Click en "Run query"**
5. Deberías ver métricas de tus pods

### Crear Dashboard Completo

**Paso 1: Crear Dashboard**
1. Click en **"+" → "Create Dashboard"**
2. Click en **"Add visualization"**
3. Selecciona **"Prometheus"**

**Paso 2: Panel 1 - Total HTTP Requests**
1. Click en **"Code"** (arriba)
2. Escribe: `sum(http_requests_received_total)`
3. **Shift + Enter**
4. Cambia título a: `Total HTTP Requests`
5. **"Back to dashboard"**

**Paso 3: Panel 2 - Request Rate**
1. **"Add" → "Visualization"**
2. Prometheus → Code
3. Query: `rate(http_requests_received_total[1m])`
4. Título: `Request Rate (req/sec)`
5. **"Back to dashboard"**

**Paso 4: Panel 3 - Memory Usage**
1. **"Add" → "Visualization"**
2. Query: `process_working_set_bytes / 1024 / 1024`
3. Título: `Memory Usage (MB)`
4. **"Back to dashboard"**

**Paso 5: Panel 4 - CPU Usage**
1. **"Add" → "Visualization"**
2. Query: `rate(process_cpu_seconds_total[1m])`
3. Título: `CPU Usage`
4. **"Back to dashboard"**

**Paso 6: Guardar Dashboard**
1. Click en **💾 "Save dashboard"**
2. Nombre: `MiAppDevOps - Observabilidad`
3. Descripción: `Paneles de monitoreo`
4. **"Save"**

---

## 📊 9. Queries PromQL Útiles

### HTTP Metrics

```promql
# Total de requests
sum(http_requests_received_total)

# Request rate (requests por segundo)
rate(http_requests_received_total[1m])

# Requests por código de estado
sum by (code) (http_requests_received_total)

# Latencia promedio (segundos)
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Percentil 95 de latencia
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### System Metrics

```promql
# Memoria en MB
process_working_set_bytes / 1024 / 1024

# CPU usage
rate(process_cpu_seconds_total[1m])

# Threads activos
process_num_threads

# Garbage Collections
rate(dotnet_collection_count_total[1m])
```

### Kubernetes Metrics

```promql
# Pods corriendo
count(kube_pod_status_phase{phase="Running"})

# CPU por pod
rate(container_cpu_usage_seconds_total{pod=~"miappdevops.*"}[5m])

# Memoria por pod
container_memory_working_set_bytes{pod=~"miappdevops.*"} / 1024 / 1024
```

---

## 🎯 10. Conceptos de Observabilidad

### Los 3 Pilares

**1. Métricas (Metrics)**
- Datos numéricos agregados en el tiempo
- Ejemplos: CPU, memoria, request rate
- Herramienta: Prometheus

**2. Logs**
- Eventos discretos con timestamp
- Ejemplos: errores, warnings, info
- Herramienta: Loki, ELK

**3. Traces**
- Seguimiento de requests a través de servicios
- Ejemplos: latencia por servicio, cuellos de botella
- Herramienta: Jaeger, Zipkin

### Prometheus Architecture

```
┌─────────────┐
│ Application │ ← Expone /metrics
└──────┬──────┘
       │
       │ HTTP GET /metrics
       ↓
┌─────────────┐
│ Prometheus  │ ← Scraping cada 30s
│   Server    │ ← Almacena time series
└──────┬──────┘
       │
       │ PromQL queries
       ↓
┌─────────────┐
│   Grafana   │ ← Visualización
└─────────────┘
```

### ServiceMonitor Pattern

```
ServiceMonitor (CRD)
    ↓
Prometheus Operator detecta
    ↓
Configura Prometheus automáticamente
    ↓
Prometheus scrapes Service
    ↓
Métricas disponibles
```

---

## 🚀 Comandos Útiles

### Prometheus

```bash
# Ver targets en Prometheus
# http://40.65.92.138:30090/targets

# Query directa en Prometheus
# http://40.65.92.138:30090/graph

# Ver configuración
sudo kubectl get configmap -n monitoring prometheus-prometheus-kube-prometheus-prometheus-rulefiles-0 -o yaml
```

### Grafana

```bash
# Reset password de admin
sudo kubectl exec -it -n monitoring prometheus-grafana-xxx -- grafana-cli admin reset-admin-password newpassword

# Ver logs de Grafana
sudo kubectl logs -n monitoring prometheus-grafana-xxx -c grafana

# Backup de dashboards
# Settings → JSON Model → Copy
```

### ServiceMonitor

```bash
# Listar ServiceMonitors
sudo kubectl get servicemonitor

# Ver detalles
sudo kubectl describe servicemonitor miappdevops-monitor

# Ver si Prometheus lo detectó
sudo kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 | grep miappdevops
```

---

## 🎓 Conceptos Aprendidos

### Observabilidad
- ✅ Diferencia entre monitoring y observability
- ✅ Los 3 pilares: Métricas, Logs, Traces
- ✅ Time series databases
- ✅ PromQL (Prometheus Query Language)

### Prometheus
- ✅ Pull-based monitoring
- ✅ Service discovery
- ✅ Scraping y targets
- ✅ Labels y series temporales
- ✅ Alerting rules

### Grafana
- ✅ Data sources
- ✅ Dashboards y panels
- ✅ Visualizaciones (Graph, Gauge, Table)
- ✅ Variables y templating
- ✅ Alerting

### Kubernetes Monitoring
- ✅ ServiceMonitor CRD
- ✅ Prometheus Operator
- ✅ kube-state-metrics
- ✅ node-exporter

---

## 📚 Recursos Adicionales

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [prometheus-net GitHub](https://github.com/prometheus-net/prometheus-net)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

---

## ✅ Checklist de Observabilidad

### Instalación
- [x] Helm instalado
- [x] kube-prometheus-stack desplegado
- [x] Prometheus accesible (puerto 30090)
- [x] Grafana accesible (puerto 30030)

### Aplicación
- [x] prometheus-net agregado
- [x] Middleware configurado
- [x] Endpoint /metrics expuesto
- [x] Métricas verificadas localmente

### Kubernetes
- [x] Service creado
- [x] ServiceMonitor configurado
- [x] Prometheus scrapeando métricas
- [x] Targets activos en Prometheus

### Grafana
- [x] Dashboard creado
- [x] 4 paneles configurados
- [x] Queries funcionando
- [x] Dashboard guardado

---

## 🎯 Próximos Pasos

**FASE 9 - Arquitectura Senior:**
- Patrones de diseño avanzados
- Microservicios
- Event-driven architecture
- CQRS y Event Sourcing
- API Gateway

---

## 📊 Métricas del Proyecto

- **Componentes instalados:** 6 (Prometheus, Grafana, Alertmanager, etc.)
- **Pods en monitoring:** 6
- **Métricas expuestas:** 15+
- **Paneles en dashboard:** 4
- **Tiempo de instalación:** ~5 minutos
- **Overhead de recursos:** ~500MB RAM

---

**Fecha:** 21 Feb 2026  
**Autor:** Fabian Bele  
**Fase:** 8/10 - Observabilidad (Monitoring & Logging)
