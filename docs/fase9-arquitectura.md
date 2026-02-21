# 🏗️ FASE 9 - Arquitectura Senior (Microservicios)

> Refactorización de monolito a arquitectura de microservicios

---

## 📋 Objetivos

- ✅ Crear microservicio Backend API
- ✅ Separar responsabilidades (Frontend/Backend)
- ✅ Comunicación entre servicios
- ✅ Despliegue independiente
- ✅ Escalado independiente

---

## 🏗️ Arquitectura

### Antes (Monolito)
```
Usuario → NodePort → App .NET (Todo en uno)
```

### Después (Microservicios)
```
Usuario → NodePort → Frontend (.NET Web)
                          ↓
                     ClusterIP
                          ↓
                    Backend API (.NET API)
                          ↓
                    (Futuro: Database)
```

---

## 🛠️ Componentes

### 1. Frontend (miappdevops)
- **Tipo:** ASP.NET Core Razor Pages
- **Puerto:** 5000
- **Réplicas:** 3
- **Acceso:** NodePort 30080
- **Responsabilidad:** UI y presentación

### 2. Backend API (backend-api)
- **Tipo:** ASP.NET Core Web API
- **Puerto:** 5000
- **Réplicas:** 2
- **Acceso:** ClusterIP (interno)
- **Responsabilidad:** Lógica de negocio y datos

---

## 🚀 1. Creación del Backend API

### Crear Proyecto

```bash
cd ~/fabian/DevOps/azureDevops
mkdir -p backend-api
cd backend-api

# Crear Web API
dotnet new webapi -n BackendApi --no-https
cd BackendApi
```

### Estructura del Proyecto

```
backend-api/
└── BackendApi/
    ├── Program.cs              # Configuración y endpoints
    ├── BackendApi.csproj       # Dependencias
    ├── Dockerfile              # Imagen Docker
    └── appsettings.json        # Configuración
```

---

## 📝 2. Implementación del Backend API

### Program.cs

```csharp
using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure pipeline
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors("AllowAll");
app.UseHttpMetrics();

// Health check endpoint
app.MapGet("/health", () => new 
{ 
    status = "healthy", 
    service = "backend-api", 
    timestamp = DateTime.UtcNow 
})
.WithName("HealthCheck")
.WithOpenApi();

// API endpoints
app.MapGet("/api/status", () => new 
{ 
    service = "Backend API",
    version = "1.0.0",
    environment = app.Environment.EnvironmentName,
    timestamp = DateTime.UtcNow
})
.WithName("GetStatus")
.WithOpenApi();

app.MapGet("/api/data", () => 
{
    var data = Enumerable.Range(1, 10).Select(i => new 
    {
        id = i,
        name = $"Item {i}",
        value = Random.Shared.Next(1, 100),
        createdAt = DateTime.UtcNow.AddDays(-i)
    }).ToArray();
    
    return new { count = data.Length, items = data };
})
.WithName("GetData")
.WithOpenApi();

// Prometheus metrics
app.MapMetrics();

app.Run();
```

### Características

- **Minimal APIs:** Endpoints ligeros sin controllers
- **Swagger:** Documentación automática
- **CORS:** Permite llamadas desde el frontend
- **Prometheus:** Métricas integradas
- **Health checks:** Endpoint de salud

---

## 🐳 3. Dockerización

### Dockerfile

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# Usuario no-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY --from=build --chown=appuser:appuser /app .

USER appuser

EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

ENTRYPOINT ["dotnet", "BackendApi.dll"]
```

### Build y Test

```bash
# Build imagen
docker build -t backend-api:latest .

# Probar localmente
docker run -p 5001:5000 backend-api:latest

# Test endpoints
curl http://localhost:5001/health
curl http://localhost:5001/api/status
curl http://localhost:5001/api/data
curl http://localhost:5001/metrics
```

---

## ☸️ 4. Despliegue en Kubernetes

### Manifiestos (k8s/backend-api.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  labels:
    app: backend-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: backend-api
        image: backend-api:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: backend-api
  labels:
    app: backend-api
spec:
  type: ClusterIP
  selector:
    app: backend-api
  ports:
  - name: http
    port: 5000
    targetPort: 5000
```

### Deploy

```bash
# Guardar y transferir imagen
docker save backend-api:latest | gzip > backend-api.tar.gz
scp -i ~/.ssh/id_rsa backend-api.tar.gz azureuser@40.65.92.138:/home/azureuser/

# En la VM
ssh -i ~/.ssh/id_rsa azureuser@40.65.92.138
sudo k3s ctr images import backend-api.tar.gz
sudo kubectl apply -f - < backend-api.yaml

# Verificar
sudo kubectl get pods -l app=backend-api
sudo kubectl get svc backend-api
```

---

## 🔗 5. Comunicación entre Servicios

### Service Discovery

Kubernetes proporciona DNS interno automático:

```
http://backend-api:5000          # Mismo namespace
http://backend-api.default:5000  # Con namespace
http://backend-api.default.svc.cluster.local:5000  # FQDN completo
```

### Probar Comunicación

```bash
# Port-forward para testing
sudo kubectl port-forward svc/backend-api 8081:5000 &

# Test desde VM
curl http://localhost:8081/health
curl http://localhost:8081/api/data

# Test desde otro pod
sudo kubectl run test-pod --rm -it --image=curlimages/curl --restart=Never \
  -- curl http://backend-api:5000/health
```

---

## 📊 6. Arquitectura de Microservicios

### Ventajas Implementadas

**1. Despliegue Independiente**
- Frontend y Backend se despliegan por separado
- Actualizaciones sin afectar otros servicios

**2. Escalado Independiente**
- Frontend: 3 réplicas (más tráfico de usuarios)
- Backend: 2 réplicas (menos carga)

**3. Tecnologías Diferentes**
- Frontend: Razor Pages (UI)
- Backend: Web API (REST)
- Futuro: Diferentes lenguajes si es necesario

**4. Resiliencia**
- Si Backend falla, Frontend sigue funcionando
- Health checks detectan problemas
- Kubernetes reinicia pods automáticamente

**5. Seguridad**
- Backend no expuesto externamente (ClusterIP)
- Solo Frontend tiene acceso público (NodePort)
- Network Policies pueden restringir comunicación

---

## 🎯 7. Patrones de Diseño

### Service Mesh (Simplificado)

```
Frontend → Service Discovery → Backend
    ↓
Load Balancing (Kubernetes)
    ↓
Backend Pod 1, Backend Pod 2
```

### API Gateway Pattern

```
Usuario → Frontend (Gateway) → Backend Services
                                    ↓
                              Service 1, Service 2, Service N
```

### Circuit Breaker (Futuro)

```csharp
// Implementación con Polly
services.AddHttpClient("backend")
    .AddTransientHttpErrorPolicy(p => 
        p.CircuitBreakerAsync(5, TimeSpan.FromSeconds(30)));
```

---

## 🚀 Comandos Útiles

### Desarrollo

```bash
# Crear nuevo microservicio
dotnet new webapi -n ServiceName --no-https

# Agregar dependencias
dotnet add package prometheus-net.AspNetCore

# Ejecutar localmente
dotnet run
```

### Docker

```bash
# Build
docker build -t service-name:latest .

# Run
docker run -p 5001:5000 service-name:latest

# Logs
docker logs <container-id>
```

### Kubernetes

```bash
# Deploy
kubectl apply -f service.yaml

# Ver pods
kubectl get pods -l app=service-name

# Logs
kubectl logs -l app=service-name --tail=50

# Port-forward
kubectl port-forward svc/service-name 8080:5000

# Escalar
kubectl scale deployment service-name --replicas=3

# Eliminar
kubectl delete -f service.yaml
```

---

## 📈 Métricas y Monitoreo

### Endpoints de Métricas

Ambos servicios exponen `/metrics`:

```bash
# Frontend
curl http://miappdevops:5000/metrics

# Backend
curl http://backend-api:5000/metrics
```

### ServiceMonitor (Futuro)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-api-monitor
  labels:
    app: backend-api
    release: prometheus
spec:
  selector:
    matchLabels:
      app: backend-api
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

---

## 🎓 Conceptos Aprendidos

### Microservicios
- ✅ Separación de responsabilidades
- ✅ Despliegue independiente
- ✅ Escalado independiente
- ✅ Service Discovery
- ✅ Load Balancing

### Kubernetes
- ✅ ClusterIP vs NodePort
- ✅ Service Discovery DNS
- ✅ Pod-to-Pod communication
- ✅ Health checks
- ✅ Resource limits

### .NET
- ✅ Minimal APIs
- ✅ Swagger/OpenAPI
- ✅ CORS configuration
- ✅ Dependency Injection
- ✅ Environment configuration

---

## 🔜 Próximos Pasos (Fase 10)

**Mejoras Arquitectónicas:**
- API Gateway (NGINX Ingress)
- Service Mesh (Linkerd/Istio)
- Message Queue (RabbitMQ/Kafka)
- Database (PostgreSQL/MongoDB)
- Caching (Redis)
- Distributed Tracing (Jaeger)

---

## 📚 Recursos Adicionales

- [Microservices Architecture](https://microservices.io/)
- [.NET Minimal APIs](https://docs.microsoft.com/aspnet/core/fundamentals/minimal-apis)
- [Kubernetes Service Discovery](https://kubernetes.io/docs/concepts/services-networking/service/)
- [12 Factor App](https://12factor.net/)

---

**Fecha:** 21 Feb 2026  
**Autor:** Fabian Bele  
**Fase:** 9/10 - Arquitectura Senior (Microservicios)
