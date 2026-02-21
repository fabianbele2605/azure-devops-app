# 📘 FASE 6 — Contenedores y Kubernetes

> Orquestación de contenedores con Kubernetes (K3s)

---

## 🎯 Objetivo

Desplegar aplicaciones en Kubernetes, aprendiendo orquestación de contenedores, escalado automático y alta disponibilidad.

**Lo que aprenderás:**
- ✅ Conceptos fundamentales de Kubernetes
- ✅ Deployments y ReplicaSets
- ✅ Services y exposición de aplicaciones
- ✅ Escalado horizontal
- ✅ Self-healing y recuperación automática
- ✅ Gestión de recursos (CPU/memoria)

---

## 🤔 El Desafío: Cuotas de Azure

### Problema encontrado

Al intentar crear Azure Kubernetes Service (AKS):

```
Error: ErrCode_InsufficientVCPUQuota
left regional vcpu quota 0, requested quota 2
```

**Causa:** Las cuentas trial de Azure tienen cuotas regionales separadas para AKS, independientes de las VMs normales.

### Solución: K3s

**K3s** es Kubernetes ligero y certificado por CNCF:
- ✅ 100% compatible con Kubernetes
- ✅ Mismos comandos kubectl
- ✅ Mismo comportamiento
- ✅ Usado en producción (edge computing, IoT)
- ✅ Desarrollado por Rancher Labs (SUSE)

**Ventaja:** Corre en tu VM existente sin necesitar recursos adicionales.

---

## 📦 PASO 1: Instalación de kubectl

### ¿Qué es kubectl?

CLI para interactuar con clusters Kubernetes (como `az` para Azure o `docker` para Docker).

### Instalación

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verificación

```bash
kubectl version --client
```

✅ **kubectl instalado**

---

## 🚀 PASO 2: Instalación de K3s

### Conectar a la VM

```bash
ssh azureuser@<IP_PUBLICA>
```

### Instalar K3s (1 comando)

```bash
curl -sfL https://get.k3s.io | sh -
```

**¿Qué hace?**
- Descarga K3s
- Instala binarios
- Configura systemd service
- Inicia el cluster automáticamente

**Tiempo:** ~30 segundos

### Resultado

```
[INFO]  Using v1.34.4+k3s1 as release
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  systemd: Starting k3s
```

### Verificar cluster

```bash
sudo k3s kubectl get nodes
```

**Output:**
```
NAME           STATUS   ROLES           AGE   VERSION
vm-terraform   Ready    control-plane   3s    v1.34.4+k3s1
```

✅ **Cluster Kubernetes funcionando**

---

## 📝 PASO 3: Crear Manifiestos de Kubernetes

### ¿Qué son los manifiestos?

Archivos YAML que describen el estado deseado de los recursos en Kubernetes.

### Estructura del proyecto

```bash
cd ~/fabian/DevOps/azureDevops
mkdir k8s
cd k8s
```

---

### 3.1 - Deployment

**Archivo:** `k8s/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miappdevops
  labels:
    app: miappdevops
spec:
  replicas: 2
  selector:
    matchLabels:
      app: miappdevops
  template:
    metadata:
      labels:
        app: miappdevops
    spec:
      containers:
      - name: miappdevops
        image: miappdevops:latest
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
```

**Explicación:**

**Metadata:**
- `name`: Nombre del deployment
- `labels`: Etiquetas para identificar recursos

**Spec:**
- `replicas: 2`: Crea 2 copias (pods) de la aplicación
- `selector`: Cómo identificar los pods que gestiona
- `template`: Plantilla para crear pods

**Container:**
- `image`: Imagen Docker a usar
- `imagePullPolicy: Never`: No descargar, usar imagen local
- `containerPort: 5000`: Puerto donde escucha la app
- `resources`: Límites de CPU y memoria

**Resources:**
- `requests`: Recursos mínimos garantizados
- `limits`: Recursos máximos permitidos

---

### 3.2 - Service

**Archivo:** `k8s/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: miappdevops-service
spec:
  type: NodePort
  selector:
    app: miappdevops
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
      nodePort: 30080
```

**Explicación:**

**Type: NodePort**
- Expone el servicio en un puerto del nodo
- Accesible desde fuera del cluster

**Selector:**
- `app: miappdevops`: Conecta con pods que tengan esta etiqueta

**Ports:**
- `port: 80`: Puerto del servicio (interno)
- `targetPort: 5000`: Puerto del contenedor
- `nodePort: 30080`: Puerto expuesto en el nodo (30000-32767)

**Flujo de tráfico:**
```
Internet → NodePort:30080 → Service:80 → Pod:5000
```

---

## 🐳 PASO 4: Preparar Imagen Docker

### Build de la imagen

```bash
cd ~/fabian/DevOps/azureDevops/app
docker build -t miappdevops:latest .
```

### Comprimir imagen

```bash
docker save miappdevops:latest | gzip > miappdevops.tar.gz
```

### Copiar a la VM

```bash
scp miappdevops.tar.gz azureuser@<IP_VM>:/home/azureuser/
```

**Resultado:**
```
miappdevops.tar.gz    100%   86MB  12.6MB/s   00:06
```

✅ **Imagen transferida**

---

## 📤 PASO 5: Cargar Imagen en K3s

### Conectar a la VM

```bash
ssh azureuser@<IP_VM>
```

### Importar imagen

```bash
sudo k3s ctr images import miappdevops.tar.gz
```

**Output:**
```
docker.io/library/miappdevops:latest    saved
Importing elapsed: 7.2 s
```

### Verificar

```bash
sudo k3s crictl images | grep miappdevops
```

**Output:**
```
docker.io/library/miappdevops    latest    d6b0f8b72d44b    229MB
```

✅ **Imagen disponible en K3s**

---

## 🚀 PASO 6: Desplegar en Kubernetes

### Copiar manifiestos a la VM

Desde tu máquina local:

```bash
cd ~/fabian/DevOps/azureDevops
scp k8s/*.yaml azureuser@<IP_VM>:/home/azureuser/
```

### Aplicar manifiestos

En la VM:

```bash
sudo k3s kubectl apply -f deployment.yaml
sudo k3s kubectl apply -f service.yaml
```

**Output:**
```
deployment.apps/miappdevops created
service/miappdevops-service created
```

### Verificar pods

```bash
sudo k3s kubectl get pods
```

**Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
miappdevops-848586889b-2zgzz   1/1     Running   0          25s
miappdevops-848586889b-zns58   1/1     Running   0          25s
```

**¡2 réplicas corriendo!** ✅

### Verificar service

```bash
sudo k3s kubectl get services
```

**Output:**
```
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes            ClusterIP   10.43.0.1       <none>        443/TCP        17m
miappdevops-service   NodePort    10.43.251.231   <none>        80:30080/TCP   22s
```

✅ **Service expuesto en puerto 30080**

---

## 🌐 PASO 7: Exponer al Exterior

### Abrir puerto en NSG

Desde tu máquina local:

```bash
cd ~/fabian/DevOps/azureDevops/terraform
az network nsg rule create \
  --resource-group rg-terraform-demo \
  --nsg-name nsg-terraform \
  --name AllowK8sApp \
  --priority 1003 \
  --destination-port-ranges 30080 \
  --access Allow \
  --protocol Tcp
```

### Probar desde terminal

```bash
curl http://<IP_VM>:30080
```

**Output:**
```html
<h1 class="display-4">¡Bienvenido a nuestra aplicación!</h1>
```

### Probar desde navegador

```
http://<IP_VM>:30080
```

✅ **Aplicación accesible públicamente**

---

## 🎮 PASO 8: Operaciones de Kubernetes

### Ver logs de un pod

```bash
sudo k3s kubectl logs miappdevops-848586889b-2zgzz
```

**Output:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://[::]:5000
info: Microsoft.Hosting.Lifetime[0]
      Application started.
```

---

### Escalar réplicas

```bash
sudo k3s kubectl scale deployment miappdevops --replicas=3
```

**Output:**
```
deployment.apps/miappdevops scaled
```

**Verificar:**
```bash
sudo k3s kubectl get pods
```

**Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
miappdevops-848586889b-2zgzz   1/1     Running   0          8m53s
miappdevops-848586889b-nsgfn   1/1     Running   0          12s
miappdevops-848586889b-zns58   1/1     Running   0          8m53s
```

**¡3 réplicas corriendo!** 🚀

---

### Describir deployment

```bash
sudo k3s kubectl describe deployment miappdevops
```

**Output importante:**
```
Replicas:       3 desired | 3 updated | 3 total | 3 available
StrategyType:   RollingUpdate
Events:
  ScalingReplicaSet  Scaled up from 2 to 3
```

---

### Self-healing (auto-recuperación)

**Eliminar un pod:**

```bash
sudo k3s kubectl delete pod miappdevops-848586889b-2zgzz
```

**Verificar inmediatamente:**

```bash
sudo k3s kubectl get pods
```

**Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
miappdevops-848586889b-9p46x   1/1     Running   0          4s    ← NUEVO
miappdevops-848586889b-nsgfn   1/1     Running   0          55s
miappdevops-848586889b-zns58   1/1     Running   0          9m36s
```

**¡Kubernetes recreó el pod automáticamente!** ✨

---

## 🎓 Conceptos de Kubernetes

### 1. Pod

**Unidad mínima de Kubernetes**
- Contiene 1 o más contenedores
- Comparten red y almacenamiento
- Efímeros (se pueden destruir y recrear)

```
Pod = 1+ Contenedores + IP compartida + Volúmenes
```

---

### 2. Deployment

**Gestiona ReplicaSets y Pods**
- Define el estado deseado
- Crea y gestiona réplicas
- Actualiza aplicaciones (rolling updates)
- Rollback automático si falla

**Jerarquía:**
```
Deployment
  └── ReplicaSet
        ├── Pod 1
        ├── Pod 2
        └── Pod 3
```

---

### 3. ReplicaSet

**Mantiene número de réplicas**
- Asegura X pods corriendo siempre
- Crea pods si faltan
- Elimina pods si sobran
- Gestionado automáticamente por Deployment

---

### 4. Service

**Expone pods con IP estable**
- Load balancer interno
- DNS interno
- Descubrimiento de servicios

**Tipos:**
- `ClusterIP`: Solo interno (default)
- `NodePort`: Expone en puerto del nodo
- `LoadBalancer`: Balanceador externo (cloud)
- `ExternalName`: Alias DNS

---

### 5. Labels y Selectors

**Labels:** Etiquetas key-value en recursos

```yaml
labels:
  app: miappdevops
  tier: frontend
```

**Selectors:** Filtran recursos por labels

```yaml
selector:
  matchLabels:
    app: miappdevops
```

**Uso:** Conectan Services con Pods, Deployments con ReplicaSets, etc.

---

### 6. Resources (Recursos)

**Requests:** Recursos garantizados

```yaml
requests:
  memory: "128Mi"
  cpu: "100m"
```

**Limits:** Recursos máximos

```yaml
limits:
  memory: "256Mi"
  cpu: "200m"
```

**CPU:**
- `100m` = 0.1 CPU (100 milicores)
- `1000m` = 1 CPU completa

**Memoria:**
- `128Mi` = 128 Mebibytes
- `1Gi` = 1 Gibibyte

---

## 🔄 Flujo Completo

```
1. Developer hace cambio en código
   ↓
2. Build imagen Docker
   ↓
3. Push imagen a registry (o cargar en K3s)
   ↓
4. kubectl apply -f deployment.yaml
   ↓
5. Kubernetes crea/actualiza pods
   ↓
6. Service balancea tráfico entre pods
   ↓
7. Usuario accede a la aplicación
```

---

## 🆚 Kubernetes vs Docker

| Aspecto | Docker | Kubernetes |
|---------|--------|------------|
| Propósito | Ejecutar contenedores | Orquestar contenedores |
| Escalado | Manual | Automático |
| Self-healing | No | Sí |
| Load balancing | Manual | Automático |
| Rolling updates | No | Sí |
| Declarativo | No | Sí |
| Multi-host | No nativo | Sí |

**Conclusión:** Docker corre contenedores, Kubernetes los gestiona a escala.

---

## 📊 Comandos Útiles de kubectl

### Ver recursos

```bash
# Pods
kubectl get pods
kubectl get pods -o wide  # Más detalles
kubectl get pods --watch  # Monitoreo en tiempo real

# Deployments
kubectl get deployments
kubectl get deploy

# Services
kubectl get services
kubectl get svc

# Todo
kubectl get all
```

---

### Describir recursos

```bash
kubectl describe pod <nombre-pod>
kubectl describe deployment <nombre-deployment>
kubectl describe service <nombre-service>
```

---

### Logs

```bash
# Logs de un pod
kubectl logs <nombre-pod>

# Logs en tiempo real
kubectl logs -f <nombre-pod>

# Logs de contenedor específico
kubectl logs <nombre-pod> -c <nombre-contenedor>
```

---

### Ejecutar comandos en pods

```bash
# Shell interactivo
kubectl exec -it <nombre-pod> -- /bin/bash

# Comando único
kubectl exec <nombre-pod> -- ls /app
```

---

### Escalar

```bash
# Escalar deployment
kubectl scale deployment <nombre> --replicas=5

# Auto-scaling (HPA)
kubectl autoscale deployment <nombre> --min=2 --max=10 --cpu-percent=80
```

---

### Actualizar

```bash
# Actualizar imagen
kubectl set image deployment/<nombre> <contenedor>=<nueva-imagen>

# Editar deployment
kubectl edit deployment <nombre>

# Aplicar cambios
kubectl apply -f deployment.yaml
```

---

### Eliminar

```bash
# Eliminar pod (se recrea automáticamente)
kubectl delete pod <nombre-pod>

# Eliminar deployment (elimina pods también)
kubectl delete deployment <nombre>

# Eliminar service
kubectl delete service <nombre>

# Eliminar todo de un archivo
kubectl delete -f deployment.yaml
```

---

## 🎯 Casos de Uso Reales

### 1. Zero-downtime deployments

```bash
# Actualizar imagen sin downtime
kubectl set image deployment/miappdevops miappdevops=miappdevops:v2
```

Kubernetes hace rolling update:
- Crea nuevos pods con v2
- Espera que estén Ready
- Elimina pods viejos v1
- Sin interrupción del servicio

---

### 2. Rollback

```bash
# Ver historial
kubectl rollout history deployment/miappdevops

# Rollback a versión anterior
kubectl rollout undo deployment/miappdevops

# Rollback a versión específica
kubectl rollout undo deployment/miappdevops --to-revision=2
```

---

### 3. Health checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

- **Liveness:** ¿Está vivo? Si no, reiniciar
- **Readiness:** ¿Está listo? Si no, no enviar tráfico

---

## 🔐 Mejores Prácticas

### 1. Siempre definir resources

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

**Por qué:** Evita que un pod consuma todos los recursos del nodo.

---

### 2. Usar health checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
readinessProbe:
  httpGet:
    path: /ready
    port: 5000
```

**Por qué:** Kubernetes puede detectar y recuperar pods problemáticos.

---

### 3. Múltiples réplicas

```yaml
replicas: 3  # Mínimo 2 para HA
```

**Por qué:** Alta disponibilidad y tolerancia a fallos.

---

### 4. Labels consistentes

```yaml
labels:
  app: miappdevops
  version: v1
  tier: frontend
```

**Por qué:** Facilita gestión y selección de recursos.

---

### 5. Namespaces para organizar

```bash
kubectl create namespace production
kubectl create namespace staging
```

**Por qué:** Aísla recursos por ambiente.

---

## 🎓 Conceptos Aprendidos

✅ **Kubernetes** - Orquestador de contenedores  
✅ **K3s** - Kubernetes ligero certificado  
✅ **Pods** - Unidad mínima de despliegue  
✅ **Deployments** - Gestión de réplicas  
✅ **ReplicaSets** - Mantiene número de pods  
✅ **Services** - Exposición y load balancing  
✅ **Labels/Selectors** - Organización de recursos  
✅ **Resources** - Límites de CPU/memoria  
✅ **Self-healing** - Recuperación automática  
✅ **Scaling** - Escalado horizontal  
✅ **Rolling updates** - Actualizaciones sin downtime  

---

## 📚 Recursos Adicionales

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [K3s Docs](https://docs.k3s.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Patterns](https://k8spatterns.io/)

---

## ⏭️ Próximos pasos

### Nivel Intermedio
- [ ] ConfigMaps y Secrets
- [ ] Persistent Volumes
- [ ] Ingress Controllers
- [ ] Horizontal Pod Autoscaler (HPA)

### Nivel Avanzado
- [ ] StatefulSets
- [ ] DaemonSets
- [ ] Jobs y CronJobs
- [ ] Network Policies
- [ ] Helm Charts

---

**Completado:** 21 Feb 2026 ✅

**Logros:**
- ✅ K3s instalado y funcionando
- ✅ Aplicación desplegada con 3 réplicas
- ✅ Service expuesto públicamente
- ✅ Self-healing demostrado
- ✅ Escalado horizontal funcionando
- ✅ Load balancing automático

**¡Nivel Kubernetes alcanzado!** 🚀
