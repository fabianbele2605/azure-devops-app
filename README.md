# 🚀 Azure DevOps - Proyecto de Aprendizaje

> Ruta completa de aprendizaje DevOps con Azure, desde fundamentos hasta Kubernetes

[![CI/CD Pipeline](https://github.com/fabianbele2605/azure-devops-app/actions/workflows/deploy.yml/badge.svg)](https://github.com/fabianbele2605/azure-devops-app/actions)

---

## 📋 Descripción

Proyecto práctico de aprendizaje DevOps que cubre:
- Infraestructura en Azure
- Control de versiones con Git
- CI/CD con GitHub Actions
- Infraestructura como Código (Terraform)
- Contenedores con Docker
- Aplicaciones .NET

---

## 🏗️ Arquitectura

```
GitHub → GitHub Actions → Docker Build → Azure VM
                                           ↓
                                    App .NET en Docker
                                    (http://IP:5000)
```

---

## 🛠️ Stack Tecnológico

- **Cloud:** Azure (VMs, VNet, NSG, IPs)
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Contenedores:** Docker, K3s (Kubernetes)
- **Aplicación:** .NET 8.0 (ASP.NET Core)
- **Monitoring:** Prometheus, Grafana, AlertManager
- **Security:** Trivy, Security Context, Network Policies, Azure Key Vault
- **Secrets:** Azure Key Vault con Managed Identity
- **OS:** Ubuntu 22.04 LTS
- **Control de Versiones:** Git

---

## 📚 Documentación por Fases

### [FASE 2 - Fundamentos de Azure](docs/aprendizaje-azure.md)
- Creación de infraestructura básica
- Resource Groups, VNet, Subnet, NSG
- Virtual Machines
- Configuración de red

### [FASE 3 - Git Profesional](docs/fase3-git-profesional.md)
- Rebase vs Merge
- Conventional Commits
- Git Hooks
- Mejores prácticas

### [FASE 4 - CI/CD Profesional](docs/fase4-cicd-profesional.md)
- Aplicación .NET + Docker
- GitHub Actions Workflows
- Deploy automático
- Multi-stage Docker builds

### [FASE 5 - Terraform (IaC)](docs/fase5-terraform.md)
- Infraestructura como Código
- Automatización completa
- Reproducibilidad
- Gestión de estado

### [FASE 6 - Kubernetes (K3s)](docs/fase6-kubernetes.md)
- Instalación de K3s
- Deployments y Services
- Escalado y self-healing
- NodePort para acceso externo

### [FASE 7 - Seguridad (DevSecOps)](docs/fase7-seguridad.md)
- Escaneo de vulnerabilidades con Trivy
- Security hardening de Dockerfile
- Security Context en Kubernetes
- Network Policies
- Integración de seguridad en CI/CD

### [FASE 8 - Observabilidad](docs/fase8-observabilidad.md)
- Prometheus para métricas
- Grafana para visualización
- Métricas de aplicación .NET
- Dashboards personalizados
- ServiceMonitor y auto-discovery

### [FASE 9 - Arquitectura (Microservicios)](docs/fase9-arquitectura.md)
- Microservicio Backend API
- Separación Frontend/Backend
- Comunicación entre servicios
- Despliegue independiente

### [FASE 10 - Mentalidad Plataforma](docs/guia-desarrollador.md)
- Platform Engineering
- Guía del desarrollador
- Golden Paths
- Self-service infrastructure

### [FASE 11 - Terraform Profesional](docs/fase11-terraform-profesional.md)
- Remote backend en Azure Storage
- State locking con Azure Blob
- Entornos separados (dev/prod)
- NSG restringido por IP

### [FASE 12 - CI/CD Profesional](docs/fase12-cicd-profesional.md)
- Pipeline multi-stage (test → security-scan → deploy)
- Tests con xUnit
- Trivy security scanning
- Versiones pinneadas de actions

### [FASE 13 - Kubernetes Producción](docs/fase13-kubernetes-produccion.md)
- Tags inmutables (v1.0.0)
- HorizontalPodAutoscaler (HPA)
- PodDisruptionBudget (PDB)
- Resource requests y limits

### [FASE 14 - Seguridad y Observabilidad](docs/fase14-seguridad-observabilidad.md)
- Alertas con Prometheus/AlertManager
- PrometheusRule personalizado
- Azure Key Vault para secrets
- Managed Identity sin credenciales

---

## 🚀 Quick Start

### Prerequisitos

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# .NET SDK
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Docker
sudo apt install docker.io -y
```

### Autenticación en Azure

```bash
az login
```

### Desplegar Infraestructura con Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Ejecutar Aplicación Localmente

```bash
cd app
dotnet run
# Abre http://localhost:5000
```

### Build Docker Image

```bash
cd app
docker build -t miappdevops .
docker run -p 5000:5000 miappdevops
```

---

## 📁 Estructura del Proyecto

```
azure-devops-app/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD
├── app/
│   ├── Pages/                  # Páginas Razor
│   ├── wwwroot/                # Archivos estáticos
│   ├── Program.cs              # Punto de entrada
│   ├── Dockerfile              # Imagen Docker
│   └── MiAppDevOps.csproj      # Configuración .NET
├── terraform/
│   ├── provider.tf             # Provider Azure
│   ├── variables.tf            # Variables
│   ├── main.tf                 # Recursos principales
│   └── outputs.tf              # Outputs
├── docs/
│   ├── aprendizaje-azure.md    # FASE 2
│   ├── fase3-git-profesional.md
│   ├── fase4-cicd-profesional.md
│   └── fase5-terraform.md
└── README.md                   # Este archivo
```

---

## 🔄 Pipeline CI/CD

El pipeline se ejecuta automáticamente en cada push a `main`:

1. **Checkout** - Descarga el código
2. **Build** - Construye imagen Docker
3. **Save** - Comprime la imagen
4. **Deploy** - Copia a Azure VM vía SCP
5. **Run** - Ejecuta contenedor en la VM

**Tiempo total:** ~50 segundos

---

## 🌐 Aplicación Desplegada

**URL:** http://20.114.13.52:5000

**Características:**
- Aplicación web ASP.NET Core
- Dockerizada con multi-stage build
- Deploy automático con GitHub Actions
- Running en Azure VM

---

## 💰 Gestión de Costos

### Apagar VM cuando no la uses

```bash
az vm deallocate \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

### Encender VM

```bash
az vm start \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

### Destruir toda la infraestructura

```bash
cd terraform
terraform destroy
```

---

## 🎓 Conceptos Aprendidos

### Azure
- ✅ Resource Groups
- ✅ Virtual Networks (VNet)
- ✅ Network Security Groups (NSG)
- ✅ Virtual Machines
- ✅ Public IPs
- ✅ Network Interfaces

### DevOps
- ✅ CI/CD Pipelines
- ✅ Infrastructure as Code (IaC)
- ✅ Containerization
- ✅ Automated Deployments
- ✅ Git Workflows

### Herramientas
- ✅ Azure CLI
- ✅ Terraform
- ✅ Docker
- ✅ GitHub Actions
- ✅ .NET SDK

---

## 🔐 Secrets Configurados

En GitHub Settings → Secrets:

- `VM_HOST` - IP pública de la VM
- `VM_USERNAME` - Usuario SSH
- `VM_SSH_KEY` - Clave privada SSH

---

## 📊 Métricas del Proyecto

- **Líneas de código:** ~5000+
- **Archivos de documentación:** 14
- **Microservicios:** 2 (Frontend + Backend)
- **Recursos de Azure:** 9 (+ Key Vault)
- **Pods en Kubernetes:** 20 (+ AlertManager)
- **Alertas configuradas:** 2 (PodDown, InsufficientPods)
- **Secrets gestionados:** 2 (db-password, api-key)
- **Tiempo de deploy:** ~2 minutos
- **Fases completadas:** 14/14 🎉

---

## 🛣️ Roadmap

### ✅ Completado
- [x] FASE 1 - Mentalidad DevOps
- [x] FASE 2 - Fundamentos de Azure
- [x] FASE 3 - Git Profesional
- [x] FASE 4 - CI/CD Profesional
- [x] FASE 5 - Terraform (IaC)
- [x] FASE 6 - Kubernetes (K3s)
- [x] FASE 7 - Seguridad (DevSecOps)
- [x] FASE 8 - Observabilidad (Monitoring)
- [x] FASE 9 - Arquitectura (Microservicios)
- [x] FASE 10 - Mentalidad Plataforma
- [x] FASE 11 - Terraform Profesional (Remote Backend)
- [x] FASE 12 - CI/CD Profesional (Multi-stage Pipeline)
- [x] FASE 13 - Kubernetes Producción (HPA, PDB)
- [x] FASE 14 - Seguridad y Observabilidad (Alertas + Key Vault)

---

## 🤝 Contribuir

Este es un proyecto de aprendizaje personal, pero las sugerencias son bienvenidas:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -m 'feat: agregar mejora'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

---

## 📝 Convenciones de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
style: formateo de código
refactor: refactorización
test: agregar tests
chore: tareas de mantenimiento
ci: cambios en CI/CD
```

---

## 📖 Recursos Adicionales

- [Documentación de Azure](https://docs.microsoft.com/azure)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [.NET Documentation](https://docs.microsoft.com/dotnet)

---

## 📧 Contacto

**Autor:** Fabian Bele  
**GitHub:** [@fabianbele2605](https://github.com/fabianbele2605)  
**Proyecto:** [azure-devops-app](https://github.com/fabianbele2605/azure-devops-app)

---

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

## 🙏 Agradecimientos

- Microsoft Azure por la plataforma cloud
- HashiCorp por Terraform
- GitHub por Actions
- La comunidad DevOps

---

**⭐ Si este proyecto te ayudó, dale una estrella en GitHub!**

---

*Última actualización: 22 Feb 2026*
