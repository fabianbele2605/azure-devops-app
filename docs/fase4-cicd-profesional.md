# 📘 FASE 4 — CI/CD Profesional en Azure

> Pipeline completo de integración y despliegue continuo

---

## 🎯 Objetivo

Crear un pipeline CI/CD profesional que:
- Compile código automáticamente
- Ejecute tests
- Construya imagen Docker
- Despliegue a Azure VM
- Todo automático al hacer push

---

## 🏗️ Arquitectura del Pipeline

```
Developer → Git Push → GitHub Actions → Build → Docker → Deploy → Azure VM
```

---

## 📦 PASO 1: Crear Aplicación .NET

### ¿Qué es .NET?

Framework de Microsoft para crear aplicaciones web, APIs, etc. Muy usado en empresas enterprise.

### Instalación de .NET SDK

```bash
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0
```

**Configurar PATH:**

```bash
echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/.dotnet' >> ~/.bashrc
source ~/.bashrc
```

**Verificar:**

```bash
dotnet --version
# Output: 8.0.418
```

---

### Crear aplicación web

```bash
cd ~/fabian/DevOps/azureDevops
dotnet new webapp -n MiAppDevOps -o app
```

**¿Qué crea?**
- `Program.cs` - Punto de entrada
- `Pages/` - Páginas Razor
- `wwwroot/` - Archivos estáticos (CSS, JS)
- `MiAppDevOps.csproj` - Configuración del proyecto

---

### Probar localmente

```bash
cd app
dotnet run
```

Abre: `http://localhost:5000`

✅ **Aplicación .NET creada y funcionando**

---

## 🐳 PASO 2: Dockerizar la Aplicación

### ¿Por qué Docker?

- ✅ Mismo entorno en desarrollo y producción
- ✅ Fácil de escalar
- ✅ Aislamiento de dependencias
- ✅ Deploy rápido

---

### Crear Dockerfile

**Ubicación:** `app/Dockerfile`

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "MiAppDevOps.dll"]
```

### Explicación del Dockerfile

**Multi-stage build:**

**Stage 1 (build):**
- Usa imagen con SDK completo
- Copia proyecto y restaura dependencias
- Compila la aplicación en modo Release

**Stage 2 (runtime):**
- Usa imagen más ligera (solo runtime)
- Copia solo los binarios compilados
- Expone puerto 5000
- Define comando de inicio

**Ventaja:** Imagen final más pequeña (~200MB vs ~700MB)

---

### Crear .dockerignore

```
bin/
obj/
.git/
.gitignore
*.md
Dockerfile
.dockerignore
```

Evita copiar archivos innecesarios a la imagen.

---

### Probar build local

```bash
cd app
docker build -t miappdevops:test .
```

**Output esperado:**
```
writing image sha256:c5e5b6a719e70981...
naming to docker.io/library/miappdevops:test
```

✅ **Aplicación dockerizada exitosamente**

---

## 📤 PASO 3: Subir a GitHub

### Crear .gitignore

```bash
cat > .gitignore << 'EOF'
bin/
obj/
*.user
*.suo
.vs/
.vscode/
*.log
appsettings.Development.json
EOF
```

### Crear repositorio en GitHub

1. Ve a https://github.com/new
2. Nombre: `azure-devops-app`
3. Público o Privado
4. NO marques "Add README"
5. Create repository

### Subir código

```bash
cd ~/fabian/DevOps/azureDevops
git add .
git commit -m "feat: crear aplicación web .NET inicial" --no-verify
git remote add origin https://github.com/TU_USUARIO/azure-devops-app.git
git branch -M main
git push -u origin main
```

✅ **Código en GitHub**

---

## 🔄 PASO 4: Crear Pipeline GitHub Actions

### ¿Qué es GitHub Actions?

Plataforma de CI/CD integrada en GitHub que ejecuta workflows automáticamente.

**Equivalencia:**
- AWS: CodePipeline
- Azure: Azure DevOps Pipelines
- GitLab: GitLab CI

---

### Crear workflow

**Ubicación:** `.github/workflows/deploy.yml`

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
        docker tag miappdevops:${{ github.sha }} miappdevops:latest
    
    - name: Save Docker image
      run: docker save miappdevops:latest | gzip > app-image.tar.gz
    
    - name: Deploy to Azure VM
      uses: appleboy/scp-action@master
      with:
        host: ${{ secrets.VM_HOST }}
        username: ${{ secrets.VM_USERNAME }}
        key: ${{ secrets.VM_SSH_KEY }}
        source: "app-image.tar.gz"
        target: "/home/azureuser/"
    
    - name: Run container on VM
      uses: appleboy/ssh-action@master
      with:
        host: ${{ secrets.VM_HOST }}
        username: ${{ secrets.VM_USERNAME }}
        key: ${{ secrets.VM_SSH_KEY }}
        script: |
          docker load < /home/azureuser/app-image.tar.gz
          docker stop miappdevops || true
          docker rm miappdevops || true
          docker run -d --name miappdevops -p 5000:5000 --restart unless-stopped miappdevops:latest
          rm /home/azureuser/app-image.tar.gz
```

---

### Explicación del Pipeline

**Trigger:**
```yaml
on:
  push:
    branches: [ main ]
```
Se ejecuta automáticamente al hacer push a main.

**Job:**
```yaml
runs-on: ubuntu-latest
```
Corre en un runner de Ubuntu (máquina virtual de GitHub).

**Steps:**

1. **Checkout** - Descarga el código del repo
2. **Build Docker image** - Construye la imagen con tag único (SHA del commit)
3. **Save Docker image** - Comprime la imagen en .tar.gz
4. **Deploy to Azure VM** - Copia la imagen a la VM vía SCP
5. **Run container** - SSH a la VM y ejecuta el contenedor

---

## 🔐 PASO 5: Configurar Secrets

### ¿Qué son los Secrets?

Variables encriptadas que GitHub Actions puede usar pero nadie puede ver.

### Secrets necesarios

1. **VM_HOST** → IP pública de tu VM (`20.114.13.52`)
2. **VM_USERNAME** → Usuario SSH (`azureuser`)
3. **VM_SSH_KEY** → Clave privada SSH

---

### Obtener clave SSH

```bash
cat ~/.ssh/id_rsa
```

Copia TODO (desde `-----BEGIN` hasta `-----END`).

---

### Configurar en GitHub

1. Ve a: `https://github.com/TU_USUARIO/azure-devops-app/settings/secrets/actions`
2. Click **New repository secret**
3. Agrega los 3 secrets:
   - Name: `VM_HOST`, Value: `20.114.13.52`
   - Name: `VM_USERNAME`, Value: `azureuser`
   - Name: `VM_SSH_KEY`, Value: (tu clave privada completa)

✅ **Secrets configurados**

---

## 🚀 PASO 6: Preparar la VM

### Encender la VM

```bash
az vm start \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

### Instalar Docker en la VM

```bash
ssh azureuser@20.114.13.52

sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker azureuser

exit
```

### Abrir puerto 5000

```bash
az network nsg rule create \
  --resource-group rg-aprendizaje-west \
  --nsg-name nsg-vm-aprendizaje \
  --name AllowApp \
  --priority 1002 \
  --source-address-prefixes '*' \
  --destination-port-ranges 5000 \
  --access Allow \
  --protocol Tcp
```

✅ **VM preparada**

---

## 🎯 PASO 7: Ejecutar el Pipeline

### Hacer push para disparar el workflow

```bash
cd ~/fabian/DevOps/azureDevops
git add .
git commit -m "ci: agregar GitHub Actions workflow" --no-verify
git push
```

### Ver el pipeline en acción

1. Ve a: `https://github.com/TU_USUARIO/azure-devops-app/actions`
2. Verás el workflow ejecutándose
3. Click en el workflow para ver logs en tiempo real

---

### Resultado esperado

```
✅ Build Docker image - 17s
✅ Save Docker image - 11s
✅ Deploy to Azure VM - 11s
✅ Run container on VM - 8s

Total: ~50s
```

---

## 🌐 PASO 8: Verificar Deploy

### Ver contenedor corriendo

```bash
ssh azureuser@20.114.13.52 "docker ps"
```

**Output:**
```
CONTAINER ID   IMAGE                COMMAND                  STATUS
1dbeca2d999b   miappdevops:latest   "dotnet MiAppDevOps.…"   Up 2 minutes
```

### Probar en navegador

Abre: **http://20.114.13.52:5000**

Deberías ver tu aplicación .NET corriendo. 🎉

---

## 🔄 PASO 9: Probar CI/CD Completo

### Hacer un cambio en la app

Edita `app/Pages/Index.cshtml`:

```html
<h1 class="display-4">¡Bienvenido a nuestra aplicación!</h1>
<p>Explora nuestras funcionalidades y descubre todo lo que puedes hacer con ASP.NET Core.</p>
```

### Commit y push

```bash
git add .
git commit -m "feat: actualizar mensaje de bienvenida" --no-verify
git push
```

### Ver el pipeline ejecutarse

1. Ve a GitHub Actions
2. Verás el nuevo workflow corriendo
3. En ~1 minuto, refresca el navegador
4. ¡El cambio está en producción! 🚀

---

## 📊 Flujo Completo del Pipeline

```
1. Developer hace cambio en código
   ↓
2. git commit -m "feat: nuevo feature"
   ↓
3. git push
   ↓
4. GitHub detecta push a main
   ↓
5. GitHub Actions inicia workflow
   ↓
6. Checkout código
   ↓
7. Build imagen Docker
   ↓
8. Comprimir imagen
   ↓
9. SCP imagen a VM
   ↓
10. SSH a VM
   ↓
11. Cargar imagen Docker
   ↓
12. Detener contenedor anterior
   ↓
13. Iniciar nuevo contenedor
   ↓
14. ✅ Deploy completado
   ↓
15. Usuario ve cambios en http://20.114.13.52:5000
```

**Tiempo total:** ~50 segundos desde push hasta producción

---

## 🎓 Conceptos aprendidos

### CI/CD
✅ **Continuous Integration** - Build y test automático  
✅ **Continuous Deployment** - Deploy automático a producción  
✅ **Pipeline as Code** - Workflow definido en YAML  

### Docker
✅ **Multi-stage builds** - Imágenes optimizadas  
✅ **Containerización** - Aplicaciones aisladas  
✅ **Docker registry** - Distribución de imágenes  

### GitHub Actions
✅ **Workflows** - Automatización de tareas  
✅ **Runners** - Máquinas que ejecutan jobs  
✅ **Secrets** - Gestión segura de credenciales  
✅ **Actions marketplace** - Reutilización de acciones  

### DevOps
✅ **Infrastructure as Code** - Todo en código  
✅ **Automation** - Eliminar pasos manuales  
✅ **Fast feedback** - Detectar errores rápido  

---

## 🔄 Mejoras posibles (Nivel avanzado)

### Tests automáticos
```yaml
- name: Run tests
  run: |
    cd app
    dotnet test
```

### Múltiples ambientes
```yaml
- name: Deploy to staging
  if: github.ref == 'refs/heads/develop'
  
- name: Deploy to production
  if: github.ref == 'refs/heads/main'
```

### Notificaciones
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
```

### Docker Registry
```yaml
- name: Push to Docker Hub
  run: |
    docker login -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
    docker push miappdevops:latest
```

---

## 🛠️ Troubleshooting

### Pipeline falla en "Deploy to Azure VM"

**Error:** `dial tcp :22: i/o timeout`

**Solución:** VM está apagada
```bash
az vm start --resource-group rg-aprendizaje-west --name vm-aprendizaje
```

---

### Pipeline falla en "Run container"

**Error:** `docker: command not found`

**Solución:** Docker no instalado en VM
```bash
ssh azureuser@20.114.13.52
sudo apt install docker.io -y
```

---

### No puedo acceder a la app en el navegador

**Solución:** Puerto 5000 no abierto en NSG
```bash
az network nsg rule create \
  --resource-group rg-aprendizaje-west \
  --nsg-name nsg-vm-aprendizaje \
  --name AllowApp \
  --priority 1002 \
  --destination-port-ranges 5000 \
  --access Allow \
  --protocol Tcp
```

---

## 💰 Gestión de costos

### Apagar VM cuando no la uses

```bash
az vm deallocate \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

**Ahorro:** ~$70/mes

### Encender cuando necesites

```bash
az vm start \
  --resource-group rg-aprendizaje-west \
  --name vm-aprendizaje
```

---

## 📚 Recursos adicionales

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [.NET Docker Images](https://hub.docker.com/_/microsoft-dotnet)
- [Azure VM Pricing](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/)

---

## ⏭️ Próxima fase

**FASE 5 - Infraestructura como Código (Terraform)**

Automatizar la creación de toda la infraestructura con código.

---

**Completado:** 21 Feb 2026 ✅

**Logros:**
- ✅ Aplicación .NET creada
- ✅ Dockerizada con multi-stage build
- ✅ Pipeline CI/CD funcionando
- ✅ Deploy automático a Azure
- ✅ Aplicación en producción
- ✅ Cambios desplegados en <1 minuto

**¡Nivel DevOps Profesional alcanzado!** 🚀
