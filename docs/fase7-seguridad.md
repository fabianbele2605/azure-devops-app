# 🔐 FASE 7 - Seguridad (DevSecOps)

> Implementación de prácticas de seguridad en el pipeline DevOps

---

## 📋 Objetivos

- ✅ Escaneo de vulnerabilidades en imágenes Docker
- ✅ Security hardening del Dockerfile
- ✅ Security Context en Kubernetes
- ✅ Network Policies
- ✅ Integración de seguridad en CI/CD

---

## 🛠️ Herramientas Utilizadas

- **Trivy**: Escáner de vulnerabilidades (Aqua Security)
- **Docker Security**: Mejores prácticas de contenedores
- **Kubernetes Security**: Security Context y Network Policies
- **GitHub Security**: SARIF reports

---

## 🔍 1. Instalación de Trivy

Trivy es un escáner de vulnerabilidades open-source que analiza:
- Imágenes Docker
- Sistemas de archivos
- Repositorios Git
- Configuraciones IaC

### Instalación

```bash
# Agregar repositorio
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

# Instalar
sudo apt update
sudo apt install trivy -y

# Verificar
trivy --version
```

---

## 🐳 2. Escaneo de Vulnerabilidades

### Escaneo Básico

```bash
# Escanear imagen completa
trivy image miappdevops:latest

# Solo vulnerabilidades CRITICAL y HIGH
trivy image --severity CRITICAL,HIGH miappdevops:latest

# Exportar a JSON
trivy image -f json -o results.json miappdevops:latest
```

### Resultados del Escaneo

**Imagen original:**
- 3 vulnerabilidades CRITICAL/HIGH
- CVE-2026-0861 (HIGH): glibc
- CVE-2023-45853 (CRITICAL): zlib
- ✅ Aplicación .NET: 0 vulnerabilidades

---

## 🛡️ 3. Security Hardening del Dockerfile

### Mejoras Implementadas

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0

# ✅ Crear usuario no-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# ✅ Copiar con permisos correctos
COPY --from=build --chown=appuser:appuser /app .

# ✅ Cambiar a usuario no-root
USER appuser

EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

# ✅ Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/ || exit 1

ENTRYPOINT ["dotnet", "MiAppDevOps.dll"]
```

### .dockerignore

```
bin/
obj/
*.tar.gz
.git/
.gitignore
README.md
Dockerfile
.dockerignore
```

**Beneficios:**
- ✅ Contenedor corre como usuario no-root (UID 1000)
- ✅ Reduce superficie de ataque
- ✅ Health checks automáticos
- ✅ Menor tamaño de imagen

---

## ☸️ 4. Security Context en Kubernetes

### Deployment con Security Context

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miappdevops
spec:
  replicas: 2
  template:
    spec:
      # Security Context a nivel de Pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      containers:
      - name: miappdevops
        image: miappdevops:latest
        
        # Security Context a nivel de Contenedor
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: false
          capabilities:
            drop:
            - ALL
        
        # Health Probes
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 30
        
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Características de Seguridad:**
- ✅ `runAsNonRoot`: Fuerza ejecución como usuario no-root
- ✅ `allowPrivilegeEscalation: false`: Previene escalada de privilegios
- ✅ `capabilities drop ALL`: Elimina todas las capabilities de Linux
- ✅ Health probes: Liveness y Readiness

---

## 🌐 5. Network Policies

### Política de Red Restrictiva

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: miappdevops-netpol
spec:
  podSelector:
    matchLabels:
      app: miappdevops
  policyTypes:
  - Ingress
  - Egress
  
  # Tráfico entrante
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5000
  
  # Tráfico saliente
  egress:
  - to:
    - podSelector: {}
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

**Reglas:**
- ✅ Ingress: Solo tráfico desde pods en el mismo namespace al puerto 5000
- ✅ Egress: Solo DNS (puerto 53) y comunicación interna
- ✅ Bloquea todo lo demás por defecto

### Aplicar Network Policy

```bash
kubectl apply -f k8s/network-policy.yaml
kubectl get networkpolicy
kubectl describe networkpolicy miappdevops-netpol
```

---

## 🔄 6. Integración en CI/CD

### Pipeline con Trivy

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: |
        cd app
        docker build -t miappdevops:${{ github.sha }} .
    
    # ✅ Escaneo de seguridad
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'miappdevops:latest'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
    
    # ✅ Subir resultados a GitHub Security
    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Deploy...
```

**Beneficios:**
- ✅ Escaneo automático en cada push
- ✅ Resultados visibles en GitHub Security tab
- ✅ Bloqueo de deploy si hay vulnerabilidades críticas (opcional)

---

## 📊 7. Verificación de Seguridad

### Verificar Dockerfile

```bash
# Build con mejoras
docker build -t miappdevops:secure app/

# Escanear
trivy image --severity CRITICAL,HIGH miappdevops:secure

# Verificar usuario
docker run --rm miappdevops:secure whoami
# Output: appuser
```

### Verificar Kubernetes

```bash
# Aplicar configuración segura
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/network-policy.yaml

# Verificar security context
kubectl get pod -l app=miappdevops -o jsonpath='{.items[0].spec.securityContext}'

# Verificar usuario del contenedor
kubectl exec -it <pod-name> -- whoami
# Output: appuser

# Ver network policies
kubectl get networkpolicy
kubectl describe networkpolicy miappdevops-netpol
```

---

## 🎯 Mejores Prácticas Implementadas

### Docker Security

- ✅ **Usuario no-root**: Contenedores corren como UID 1000
- ✅ **Multi-stage builds**: Reduce tamaño y superficie de ataque
- ✅ **Imagen base oficial**: Microsoft .NET images
- ✅ **Health checks**: Monitoreo de salud del contenedor
- ✅ **.dockerignore**: Excluye archivos innecesarios

### Kubernetes Security

- ✅ **Security Context**: runAsNonRoot, drop capabilities
- ✅ **Network Policies**: Tráfico restringido
- ✅ **Resource Limits**: CPU y memoria limitados
- ✅ **Health Probes**: Liveness y Readiness
- ✅ **No privileged containers**: allowPrivilegeEscalation: false

### CI/CD Security

- ✅ **Vulnerability Scanning**: Trivy en cada build
- ✅ **SARIF Reports**: Integración con GitHub Security
- ✅ **Secrets Management**: GitHub Secrets para credenciales
- ✅ **Automated Testing**: Escaneo antes de deploy

---

## 🔐 Conceptos de Seguridad

### Defense in Depth (Defensa en Profundidad)

Múltiples capas de seguridad:
1. **Código**: Dependencias actualizadas
2. **Imagen**: Escaneo de vulnerabilidades
3. **Contenedor**: Usuario no-root, capabilities limitadas
4. **Orquestador**: Security Context, Network Policies
5. **Red**: Firewall, NSG rules
6. **Pipeline**: Escaneo automático, gates de calidad

### Principle of Least Privilege

- Contenedores sin privilegios innecesarios
- Capabilities de Linux eliminadas
- Network policies restrictivas
- Acceso mínimo necesario

### Shift Left Security

- Escaneo temprano en el pipeline
- Detección de vulnerabilidades antes de producción
- Feedback rápido a desarrolladores

---

## 📈 Métricas de Seguridad

### Antes de DevSecOps
- ❌ Contenedores corriendo como root
- ❌ Sin escaneo de vulnerabilidades
- ❌ Sin network policies
- ❌ Sin health checks

### Después de DevSecOps
- ✅ Contenedores no-root (UID 1000)
- ✅ Escaneo automático con Trivy
- ✅ Network policies aplicadas
- ✅ Health probes configurados
- ✅ Security Context en todos los pods
- ✅ Resultados en GitHub Security

---

## 🚀 Comandos Útiles

### Trivy

```bash
# Escanear imagen
trivy image miappdevops:latest

# Solo HIGH y CRITICAL
trivy image --severity CRITICAL,HIGH miappdevops:latest

# Escanear filesystem
trivy fs .

# Escanear configuración K8s
trivy config k8s/
```

### Docker Security

```bash
# Verificar usuario
docker run --rm miappdevops:secure id

# Inspeccionar security
docker inspect miappdevops:secure | jq '.[0].Config.User'

# Health check status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Kubernetes Security

```bash
# Ver security context
kubectl get pod <pod> -o yaml | grep -A 10 securityContext

# Verificar network policies
kubectl get networkpolicy
kubectl describe netpol miappdevops-netpol

# Logs de seguridad
kubectl logs -l app=miappdevops --tail=50
```

---

## 🎓 Conceptos Aprendidos

### DevSecOps
- ✅ Shift Left Security
- ✅ Vulnerability Scanning
- ✅ Security as Code
- ✅ Automated Security Testing

### Container Security
- ✅ Non-root users
- ✅ Capability dropping
- ✅ Read-only filesystems
- ✅ Health checks

### Kubernetes Security
- ✅ Security Context
- ✅ Network Policies
- ✅ Pod Security Standards
- ✅ RBAC (Role-Based Access Control)

---

## 📚 Recursos Adicionales

- [Trivy Documentation](https://trivy.dev/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [OWASP Container Security](https://owasp.org/www-project-docker-top-10/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

---

## ✅ Checklist de Seguridad

### Dockerfile
- [x] Usuario no-root
- [x] Multi-stage build
- [x] Imagen base oficial
- [x] .dockerignore configurado
- [x] Health check definido

### Kubernetes
- [x] Security Context configurado
- [x] Network Policy aplicada
- [x] Resource limits definidos
- [x] Health probes configurados
- [x] No privileged containers

### CI/CD
- [x] Vulnerability scanning
- [x] SARIF reports
- [x] Secrets management
- [x] Automated testing

---

## 🎯 Próximos Pasos

**FASE 8 - Observabilidad:**
- Logging centralizado
- Métricas con Prometheus
- Dashboards con Grafana
- Tracing distribuido
- Alertas

---

**Fecha:** 21 Feb 2026  
**Autor:** Fabian Bele  
**Fase:** 7/10 - Seguridad (DevSecOps)
