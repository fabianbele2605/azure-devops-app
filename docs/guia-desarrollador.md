# 👨‍💻 Guía del Desarrollador

> Cómo usar la plataforma DevOps para desplegar tus aplicaciones

---

## 🎯 Bienvenido a la Plataforma

Esta plataforma te permite desplegar aplicaciones de forma rápida y segura, sin preocuparte por la infraestructura.

---

## 🚀 Quick Start (5 minutos)

### 1. Clonar Template

```bash
git clone https://github.com/fabianbele2605/azure-devops-app.git mi-app
cd mi-app
```

### 2. Desarrollar tu Aplicación

```bash
# Frontend (.NET Razor Pages)
cd app
dotnet run

# Backend (.NET Web API)
cd backend-api/BackendApi
dotnet run
```

### 3. Dockerizar

```bash
# Ya incluye Dockerfile optimizado
docker build -t mi-app:latest .
docker run -p 5000:5000 mi-app:latest
```

### 4. Desplegar

```bash
# Push a GitHub
git add .
git commit -m "feat: mi nueva app"
git push

# GitHub Actions despliega automáticamente
```

---

## 📦 Servicios Disponibles

### Kubernetes (K3s)
- **Auto-scaling:** Escala automáticamente según carga
- **Self-healing:** Reinicia pods que fallan
- **Load balancing:** Distribuye tráfico entre réplicas

### Observabilidad
- **Grafana:** http://40.65.92.138:30030 (admin/admin123)
- **Prometheus:** http://40.65.92.138:30090
- **Métricas automáticas:** Solo agrega `prometheus-net`

### Seguridad
- **Escaneo automático:** Trivy en cada build
- **Non-root containers:** Por defecto
- **Network policies:** Tráfico restringido

### CI/CD
- **Deploy automático:** En cada push a main
- **Rollback fácil:** `git revert` y push
- **Tiempo de deploy:** ~50 segundos

---

## 🏗️ Arquitectura de Referencia

### Microservicio Típico

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-servicio
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: mi-servicio
        image: mi-servicio:latest
        ports:
        - containerPort: 5000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: mi-servicio
spec:
  type: ClusterIP
  ports:
  - port: 5000
```

---

## 🎨 Golden Paths (Mejores Prácticas)

### 1. Estructura de Proyecto

```
mi-app/
├── src/                    # Código fuente
├── Dockerfile              # Imagen Docker
├── k8s/
│   ├── deployment.yaml     # Kubernetes manifests
│   └── service.yaml
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD pipeline
└── README.md
```

### 2. Dockerfile Template

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app
COPY --from=build --chown=appuser:appuser /app .
USER appuser
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "MiApp.dll"]
```

### 3. Health Checks Obligatorios

```csharp
app.MapGet("/health", () => new 
{ 
    status = "healthy", 
    service = "mi-servicio",
    timestamp = DateTime.UtcNow 
});
```

### 4. Métricas de Prometheus

```csharp
// Agregar paquete
// dotnet add package prometheus-net.AspNetCore

using Prometheus;

var app = builder.Build();
app.UseHttpMetrics();
app.MapMetrics();
```

---

## 🔧 Comandos Útiles

### Desarrollo Local

```bash
# Ejecutar app
dotnet run

# Build Docker
docker build -t mi-app .

# Test local
docker run -p 5000:5000 mi-app
```

### Kubernetes

```bash
# Ver mis pods
kubectl get pods -l app=mi-servicio

# Ver logs
kubectl logs -l app=mi-servicio --tail=50

# Escalar
kubectl scale deployment mi-servicio --replicas=3

# Port-forward para debug
kubectl port-forward svc/mi-servicio 8080:5000
```

### Monitoreo

```bash
# Ver métricas
curl http://mi-servicio:5000/metrics

# Ver en Grafana
# http://40.65.92.138:30030
```

---

## 🐛 Troubleshooting

### Mi pod no arranca

```bash
# Ver eventos
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>

# Verificar imagen
kubectl get pod <pod-name> -o yaml | grep image
```

### No puedo acceder a mi servicio

```bash
# Verificar service
kubectl get svc mi-servicio

# Verificar endpoints
kubectl get endpoints mi-servicio

# Test desde otro pod
kubectl run test --rm -it --image=curlimages/curl -- curl http://mi-servicio:5000/health
```

### Pipeline falla

```bash
# Ver logs en GitHub Actions
# https://github.com/USER/REPO/actions

# Verificar secrets
# Settings → Secrets → Actions
```

---

## 📊 Límites y Cuotas

### Por Servicio

- **CPU:** 100m request, 200m limit
- **Memoria:** 128Mi request, 256Mi limit
- **Réplicas:** 1-5 (auto-scaling)
- **Storage:** 1Gi por PVC

### Por Namespace

- **Pods:** 50 máximo
- **Services:** 20 máximo
- **CPU total:** 2 cores
- **Memoria total:** 4Gi

---

## 🆘 Soporte

### Documentación
- [Fase 1-10](../docs/)
- [README Principal](../README.md)

### Contacto
- **GitHub Issues:** Para bugs y features
- **Email:** fabian@example.com
- **Slack:** #devops-platform

---

## 🎓 Recursos de Aprendizaje

### Tutoriales
- [Desplegar tu primera app](tutorial-primera-app.md)
- [Agregar base de datos](tutorial-database.md)
- [Configurar CI/CD](tutorial-cicd.md)

### Videos
- [Platform Overview (5 min)](link)
- [Deploy Walkthrough (10 min)](link)

### Ejemplos
- [Frontend App](../app/)
- [Backend API](../backend-api/)
- [Microservicio completo](examples/full-microservice/)

---

## ✅ Checklist de Deploy

Antes de desplegar a producción:

- [ ] Health check implementado (`/health`)
- [ ] Métricas de Prometheus expuestas (`/metrics`)
- [ ] Dockerfile con usuario no-root
- [ ] Resource limits definidos
- [ ] Liveness y Readiness probes configurados
- [ ] Tests pasando
- [ ] Documentación actualizada
- [ ] Secrets en GitHub Actions (no en código)

---

**¡Bienvenido a la plataforma! Happy coding! 🚀**
