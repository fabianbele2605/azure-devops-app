# Guia de Pulido para Entrevista DevOps Azure

> Documento separado para mejorar tu perfil sin tocar la guia base del proyecto.

---

## Objetivo

Convertir tu proyecto actual en evidencia de nivel entrevista para roles DevOps Azure.

---

## Plan de Pulido en 4 Semanas

### Semana 1: CI/CD y Calidad

- Agregar etapa de tests (`dotnet test`) antes de build de imagen.
- Fallar pipeline si Trivy detecta `HIGH`/`CRITICAL`.
- Pinear GitHub Actions por version estable o commit SHA.
- Practica de entrevista:
- Explica por que los quality gates van antes del deploy.
- Explica como evitarias despliegues con imagen vulnerable.

### Semana 2: Terraform y Azure

- Configurar backend remoto para estado (`azurerm` backend + locking).
- Parametrizar por ambiente (`dev`, `qa`, `prod`) con `*.tfvars`.
- Restringir NSG para no exponer `22/80/5000` a `*`.
- Practica de entrevista:
- Explica drift, estado remoto y locking.
- Explica como haces rollback de infraestructura.

### Semana 3: Kubernetes de Produccion

- Evitar `latest` e `imagePullPolicy: Never`; usar tags inmutables.
- Agregar `HorizontalPodAutoscaler` y `PodDisruptionBudget`.
- Exponer apps por `Ingress` + TLS (no solo `NodePort`).
- Practica de entrevista:
- Explica diferencia entre liveness/readiness/startup probes.
- Explica rolling update vs canary.

### Semana 4: Seguridad y Observabilidad

- Integrar escaneo de IaC (`tfsec` o `checkov`) y secretos.
- Definir alertas minimas en Prometheus/Grafana.
- Mover secretos a Azure Key Vault y eliminar credenciales por defecto.
- Practica de entrevista:
- Explica enfoque DevSecOps "shift-left".
- Explica respuesta basica ante incidente en produccion.

---

## Checklist de Nivel Entrevista

Marca cada punto cuando lo puedas demostrar en vivo:

- Pipeline con `build`, `test`, `scan`, `deploy` y `rollback`.
- Terraform con backend remoto, variables por ambiente y validaciones.
- Dockerfile non-root, imagen minima, healthchecks y escaneo.
- Kubernetes con probes, recursos, autoscaling y politicas de red.
- Observabilidad con metricas tecnicas y alertas accionables.
- Seguridad con secretos fuera del codigo y controles en CI/CD.
- Capacidad de explicar costo/rendimiento en Azure.
- Runbook de incidentes y onboarding tecnico.

---

## Preguntas Tipicas de Entrevista

### 1) Como diseñas un pipeline robusto?

Debes cubrir:
- Orden: lint/test -> build -> scan -> deploy.
- Estrategia de rollback.
- Promocion por ambientes con aprobaciones.

### 2) Como aseguras Terraform en equipo?

Debes cubrir:
- Estado remoto compartido.
- Locking para evitar carreras.
- Politicas y validaciones en Pull Request.

### 3) Que harías si un pod se reinicia cada 2 minutos?

Debes cubrir:
- `kubectl describe pod` y eventos.
- Logs de aplicacion y contenedor.
- Recursos (OOMKilled), probes, red y dependencias.

### 4) Como manejas secretos?

Debes cubrir:
- Nada sensible en Git.
- Secret manager (Key Vault).
- Rotacion y minimo privilegio.

---

## Guion de Presentacion (10 minutos)

1. Problema: necesidad de automatizar deploy y operacion en Azure.
2. Solucion: IaC con Terraform + CI/CD + Kubernetes.
3. Seguridad: non-root, escaneo de vulnerabilidades y politicas de red.
4. Observabilidad: Prometheus + Grafana con metricas de aplicacion.
5. Mejora continua: roadmap tecnico (estado remoto, quality gates, autoscaling).

Tip: cierra mostrando una falla real que detectaste y resolviste.

---

## Rutina de Practica Semanal

- Lunes: 1 mejora de pipeline + 1 pregunta de entrevista escrita.
- Martes: 1 mejora Terraform + `terraform plan`.
- Miercoles: 1 escenario de debugging en Kubernetes.
- Jueves: 1 mejora de seguridad + decision tecnica documentada.
- Viernes: simulacion de entrevista (20 minutos).
- Sabado: retrospectiva y backlog de mejoras.
