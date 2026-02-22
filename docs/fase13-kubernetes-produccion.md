# FASE 13 - Kubernetes Producción (Nivel Entrevista)

> De Kubernetes básico a Kubernetes nivel producción con autoscaling y alta disponibilidad

---

## 🎯 Objetivo

Transformar los deployments de Kubernetes de nivel básico a **nivel producción** implementando:
- Tags inmutables en lugar de `latest`
- HorizontalPodAutoscaler (HPA) para autoscaling
- PodDisruptionBudget (PDB) para alta disponibilidad
- Resource requests y limits
- Security context mejorado

---

## 📚 Conceptos Clave

### 🔹 Tags Inmutables

**Problema con `latest`:**
```yaml
image: miappdevops:latest  # ❌ Mala práctica
```

**Problemas:**
- No sabes qué versión está corriendo
- Dificulta rollbacks
- Puede causar inconsistencias entre pods
- No es reproducible

**Solución:**
```yaml
image: miappdevops:v1.0.0  # ✅ Tag inmutable
imagePullPolicy: IfNotPresent
```

**Beneficios:**
- Versionado claro
- Rollbacks fáciles
- Reproducibilidad
- Auditoría

### 🔹 HorizontalPodAutoscaler (HPA)

**¿Qué es?**
Escala automáticamente el número de pods basado en métricas (CPU, memoria, custom).

**Ejemplo:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-miappdevops
spec:
  scaleTargetRef:
    kind: Deployment
    name: miappdevops
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Comportamiento:**
- CPU < 70% → Mantiene réplicas actuales
- CPU > 70% → Escala hacia arriba (hasta 5)
- CPU baja → Escala hacia abajo (mínimo 2)

### 🔹 PodDisruptionBudget (PDB)

**¿Qué es?**
Garantiza que un número mínimo de pods esté disponible durante disrupciones voluntarias (updates, drains, etc.).

**Ejemplo:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: miappdevops-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: miappdevops
```

**Beneficio:**
Durante un rolling update, Kubernetes garantiza que al menos 1 pod esté disponible siempre.

### 🔹 Resource Requests y Limits

**Requests:** Lo que el pod necesita garantizado
**Limits:** Máximo que puede usar

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

**Beneficios:**
- Scheduler puede tomar mejores decisiones
- Previene que un pod consuma todos los recursos
- Permite autoscaling basado en métricas

---

## 🏗️ Arquitectura Implementada

```
┌─────────────────────────────────────────────────────┐
│              HorizontalPodAutoscaler                │
│  Monitorea CPU/Memory y ajusta réplicas (2-5)      │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │   Deployment    │
         │  miappdevops    │
         │  (v1.0.0)       │
         └────────┬────────┘
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
     Pod 1     Pod 2     Pod 3
   (128Mi)   (128Mi)   (128Mi)
   (100m)    (100m)    (100m)
        │         │         │
        └─────────┴─────────┘
                  │
    ┌─────────────────────────┐
    │ PodDisruptionBudget     │
    │ minAvailable: 1         │
    │ (Garantiza HA)          │
    └─────────────────────────┘
```

---

## 🛠️ Implementación Paso a Paso

### Paso 1: Etiquetar Imágenes Docker

**Conectarse a la VM:**
```bash
ssh azureuser@<VM_IP>
```

**Ver imágenes actuales:**
```bash
sudo k3s ctr images ls | grep -E "miappdevops|backend-api"
```

**Etiquetar con versión:**
```bash
# Frontend
sudo k3s ctr images tag docker.io/library/miappdevops:latest docker.io/library/miappdevops:v1.0.0

# Backend
sudo k3s ctr images tag docker.io/library/backend-api:latest docker.io/library/backend-api:v1.0.0
```

**Verificar:**
```bash
sudo k3s ctr images ls | grep -E "miappdevops|backend-api"
```

Deberías ver ambas versiones (`latest` y `v1.0.0`).

---

### Paso 2: Crear Deployment de Producción - Frontend

**Archivo: `k8s/deployment-prod.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miappdevops
  labels:
    app: miappdevops
    version: v1.0.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: miappdevops
  template:
    metadata:
      labels:
        app: miappdevops
        version: v1.0.0
    spec:
      containers:
      - name: miappdevops
        image: miappdevops:v1.0.0  # ✅ Tag inmutable
        imagePullPolicy: IfNotPresent  # ✅ No Always
        ports:
        - containerPort: 5000
          name: http
        # ✅ Resource limits
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        # ✅ Probes mejorados
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        # ✅ Security Context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
---
# ✅ HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-miappdevops
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: miappdevops
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
---
# ✅ PodDisruptionBudget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: miappdevops-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: miappdevops
```

---

### Paso 3: Crear Deployment de Producción - Backend

**Archivo: `k8s/backend-api-prod.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  labels:
    app: backend-api
    version: v1.0.0
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
        version: v1.0.0
    spec:
      containers:
      - name: backend-api
        image: backend-api:v1.0.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
          name: http
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
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
---
apiVersion: v1
kind: Service
metadata:
  name: backend-api
spec:
  selector:
    app: backend-api
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
  type: ClusterIP
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-api
  minReplicas: 2
  maxReplicas: 4
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-api-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: backend-api
```

---

### Paso 4: Copiar y Aplicar

**Copiar archivos a la VM:**
```bash
scp k8s/deployment-prod.yaml azureuser@<VM_IP>:~/
scp k8s/backend-api-prod.yaml azureuser@<VM_IP>:~/
```

**Conectarse y aplicar:**
```bash
ssh azureuser@<VM_IP>

# Aplicar frontend
sudo kubectl apply -f deployment-prod.yaml

# Aplicar backend
sudo kubectl apply -f backend-api-prod.yaml
```

**Resultado esperado:**
```
deployment.apps/miappdevops configured
horizontalpodautoscaler.autoscaling/hpa-miappdevops created
poddisruptionbudget.policy/miappdevops-pdb created

deployment.apps/backend-api configured
service/backend-api configured
horizontalpodautoscaler.autoscaling/backend-api-hpa created
poddisruptionbudget.policy/backend-api-pdb created
```

---

### Paso 5: Verificar

**Ver deployments:**
```bash
sudo kubectl get deployments
```

**Ver HPA:**
```bash
sudo kubectl get hpa
```

**Salida esperada:**
```
NAME              REFERENCE                TARGETS                        MINPODS   MAXPODS   REPLICAS
backend-api-hpa   Deployment/backend-api   cpu: 1%/70%                    2         4         2
hpa-miappdevops   Deployment/miappdevops   cpu: 1%/70%, memory: 43%/80%   2         5         2
```

**Ver PDB:**
```bash
sudo kubectl get pdb
```

**Salida esperada:**
```
NAME              MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS
backend-api-pdb   1               N/A               1
miappdevops-pdb   1               N/A               1
```

**Ver pods con imágenes:**
```bash
sudo kubectl describe deployment miappdevops | grep Image
sudo kubectl describe deployment backend-api | grep Image
```

**Salida esperada:**
```
Image: miappdevops:v1.0.0
Image: backend-api:v1.0.0
```

---

## 📊 Comparación Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Imagen** | `latest` | `v1.0.0` |
| **ImagePullPolicy** | `Always` | `IfNotPresent` |
| **Réplicas** | Fijas (3) | Dinámicas (2-5) |
| **Autoscaling** | ❌ No | ✅ HPA |
| **Alta Disponibilidad** | ❌ No | ✅ PDB |
| **Resource Requests** | ❌ No | ✅ 128Mi, 100m |
| **Resource Limits** | ❌ No | ✅ 256Mi, 200m |
| **Security Context** | Básico | Mejorado (runAsNonRoot) |
| **Probes** | Básicos | Optimizados (timeouts, failures) |

---

## 🧪 Pruebas

### Probar Autoscaling

**Generar carga:**
```bash
# En la VM
sudo kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://miappdevops.default.svc.cluster.local:5000; done"
```

**Monitorear HPA (en otra terminal):**
```bash
watch -n 2 'sudo kubectl get hpa'
```

**Comportamiento esperado:**
- CPU sube gradualmente
- Cuando CPU > 70%, HPA escala hacia arriba
- Réplicas aumentan de 2 → 3 → 4 → 5 (máximo)
- Al detener carga, CPU baja
- Réplicas disminuyen gradualmente a 2 (mínimo)

**Detener:**
```bash
# Ctrl+C en ambas terminales
sudo kubectl delete pod load-generator
```

### Probar PodDisruptionBudget

**Simular drain de nodo:**
```bash
sudo kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

**Comportamiento esperado:**
- Kubernetes respeta el PDB
- Siempre mantiene al menos 1 pod disponible
- Drena pods gradualmente, no todos a la vez

**Revertir:**
```bash
sudo kubectl uncordon <node-name>
```

---

## 🎓 Conceptos para Entrevistas

### Pregunta 1: ¿Por qué no usar `latest` en producción?

**Respuesta:**
> "Usar `latest` es una mala práctica porque no sabes qué versión está corriendo en cada pod. Si un pod se reinicia, puede obtener una versión diferente, causando inconsistencias. Además, dificulta los rollbacks y la auditoría. En producción uso tags inmutables como `v1.0.0` con `imagePullPolicy: IfNotPresent` para garantizar que todos los pods usen la misma versión."

### Pregunta 2: ¿Cómo funciona el HorizontalPodAutoscaler?

**Respuesta:**
> "El HPA monitorea métricas como CPU y memoria cada 15 segundos. Si el promedio de CPU supera el threshold (ej: 70%), calcula cuántas réplicas necesita y escala hacia arriba. Si la carga baja, escala hacia abajo respetando el minReplicas. Usa la fórmula: `réplicas_deseadas = ceil(réplicas_actuales * (métrica_actual / métrica_objetivo))`. Es importante configurar resource requests para que funcione correctamente."

### Pregunta 3: ¿Qué es un PodDisruptionBudget y cuándo lo usas?

**Respuesta:**
> "Un PDB garantiza alta disponibilidad durante disrupciones voluntarias como rolling updates, drains o escalado de nodos. Especificas `minAvailable` o `maxUnavailable` para controlar cuántos pods pueden estar down simultáneamente. Por ejemplo, con `minAvailable: 1`, Kubernetes garantiza que siempre haya al menos 1 pod disponible durante un update. Es crítico para aplicaciones que no pueden tener downtime."

### Pregunta 4: ¿Cuál es la diferencia entre requests y limits?

**Respuesta:**
> "Requests es lo que el pod necesita garantizado. El scheduler usa esto para decidir en qué nodo colocar el pod. Limits es el máximo que puede usar. Si un pod excede el memory limit, se mata (OOMKilled). Si excede el CPU limit, se throttlea. Una buena práctica es configurar requests = limits para pods críticos (QoS Guaranteed) o requests < limits para mejor utilización de recursos (QoS Burstable)."

### Pregunta 5: ¿Cómo haces rollback de un deployment?

**Respuesta:**
> "Con tags inmutables, el rollback es simple. Kubernetes guarda el historial de ReplicaSets. Uso `kubectl rollout undo deployment/miappdevops` para volver a la versión anterior, o `kubectl rollout undo deployment/miappdevops --to-revision=2` para una versión específica. También puedo actualizar el deployment YAML con el tag anterior y hacer `kubectl apply`. El rollout es gradual respetando el PDB."

---

## 🚨 Troubleshooting

### HPA no escala

**Causa:** Metrics server no está corriendo o no hay resource requests.

**Solución:**
```bash
# Verificar metrics server
sudo kubectl get pods -n kube-system | grep metrics

# Verificar que el deployment tenga requests
sudo kubectl describe deployment miappdevops | grep -A 5 Requests
```

### Pods en estado Pending

**Causa:** No hay recursos suficientes en el nodo.

**Solución:**
```bash
# Ver eventos
sudo kubectl describe pod <pod-name>

# Ver recursos del nodo
sudo kubectl top nodes

# Reducir requests o agregar más nodos
```

### PDB bloquea drain

**Causa:** No se puede cumplir el minAvailable.

**Solución:**
```bash
# Ver PDB
sudo kubectl get pdb

# Temporalmente eliminar PDB
sudo kubectl delete pdb <pdb-name>

# Hacer drain
sudo kubectl drain <node>

# Recrear PDB
sudo kubectl apply -f deployment-prod.yaml
```

---

## 📈 Mejoras Futuras

### Nivel Avanzado

1. **Vertical Pod Autoscaler (VPA)**
   - Ajusta automáticamente requests/limits
   - Complementa al HPA

2. **Custom Metrics**
   ```yaml
   metrics:
   - type: Pods
     pods:
       metric:
         name: http_requests_per_second
       target:
         type: AverageValue
         averageValue: "1000"
   ```

3. **Cluster Autoscaler**
   - Escala nodos automáticamente
   - Trabaja con HPA

4. **Pod Priority y Preemption**
   ```yaml
   priorityClassName: high-priority
   ```

5. **Topology Spread Constraints**
   ```yaml
   topologySpreadConstraints:
   - maxSkew: 1
     topologyKey: kubernetes.io/hostname
     whenUnsatisfiable: DoNotSchedule
   ```

---

## ✅ Checklist de Completado

- [x] Imágenes etiquetadas con `v1.0.0`
- [x] Deployments actualizados con tags inmutables
- [x] HPA configurado para frontend y backend
- [x] PDB configurado para alta disponibilidad
- [x] Resource requests y limits definidos
- [x] Security context mejorado
- [x] Probes optimizados
- [x] Autoscaling probado
- [x] Documentación completa

---

## 🎯 Resultado Final

**Antes:**
- Deployments básicos con `latest`
- Sin autoscaling
- Sin garantías de disponibilidad
- Sin resource management

**Después:**
- ✅ Tags inmutables versionados
- ✅ Autoscaling automático (HPA)
- ✅ Alta disponibilidad garantizada (PDB)
- ✅ Resource management profesional
- ✅ Security hardening
- ✅ **Nivel producción profesional**

---

## 📚 Recursos Adicionales

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [PodDisruptionBudget Best Practices](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Image Pull Policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)

---

**🎉 ¡Felicitaciones! Ahora tienes Kubernetes a nivel producción**

*Siguiente paso: [FASE 14 - Seguridad y Observabilidad Avanzada](fase14-seguridad-observabilidad.md)*
