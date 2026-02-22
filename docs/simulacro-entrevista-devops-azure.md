# Simulacro de Entrevista DevOps Azure

> Documento aparte para practicar entrevista tecnica sin modificar la documentacion existente.

---

## Como usar este simulacro

- Responde cada pregunta en 2-3 minutos maximo.
- Usa formato STAR: Situacion, Tarea, Accion, Resultado.
- Si no sabes algo exacto, explica como lo investigarias en produccion.

---

## Parte 1: Elevator Pitch (2 minutos)

### Pregunta
Presenta tu proyecto DevOps Azure en 2 minutos.

### Respuesta guia
"Construí una plataforma de practica sobre Azure con Terraform, CI/CD y Kubernetes para desplegar servicios .NET. Empecé con un enfoque tipo laboratorio y luego fui endureciendo seguridad, observabilidad y operacion: use contenedores non-root, probes, autoscaling, reglas de alerta y gestion inicial de secretos con Key Vault. Mi objetivo fue demostrar capacidad de entregar software de forma automatizada y operarlo con buenas practicas. Tambien documente decisiones por fases para explicar trade-offs tecnicos en entrevistas."

---

## Parte 2: Preguntas Tecnicas (15 preguntas)

### 1) CI/CD
Pregunta: Como disenas un pipeline robusto para produccion?
Respuesta guia:
- Stages: `lint/test -> build -> security scan -> deploy -> smoke test`.
- Quality gates obligatorios antes de deploy.
- Rollback automatizable y versionado inmutable de imagenes.

### 2) Security en CI
Pregunta: Que haces si Trivy detecta vulnerabilidades CRITICAL?
Respuesta guia:
- Bloquear release en produccion.
- Abrir incidente y priorizar patch.
- Si es falso positivo, documentar excepcion temporal con fecha de expiracion.

### 3) Terraform state
Pregunta: Por que backend remoto y locking?
Respuesta guia:
- Evita drift y corrupcion por ejecuciones simultaneas.
- Permite trabajo en equipo y auditoria del estado.
- En Azure se soporta con Storage Account + blob lease.

### 4) Variables y entornos
Pregunta: Como separas dev/qa/prod en Terraform?
Respuesta guia:
- `*.tfvars` por entorno.
- Naming/tagging por ambiente.
- Pipelines separados o promotion gates.

### 5) Kubernetes probes
Pregunta: Diferencia entre liveness, readiness y startup probe.
Respuesta guia:
- Liveness: reinicia si la app se queda colgada.
- Readiness: controla si recibe trafico.
- Startup: da ventana de arranque para apps lentas.

### 6) Incidente de pod reiniciando
Pregunta: Que harías si un pod reinicia cada 2 minutos?
Respuesta guia:
- `kubectl describe pod` y eventos.
- Revisar logs y razon (`OOMKilled`, probe failures, crashloop).
- Validar requests/limits, dependencias y config.

### 7) Escalabilidad
Pregunta: Como configuras HPA correctamente?
Respuesta guia:
- Basado en metricas de CPU/memoria o custom metrics.
- Requests/limits coherentes.
- Validar comportamiento con carga controlada.

### 8) Despliegues sin downtime
Pregunta: Que estrategia usarias para cambios criticos?
Respuesta guia:
- Rolling update para cambios normales.
- Canary/blue-green para cambios de alto riesgo.
- Monitoreo y rollback rapido.

### 9) Secret management
Pregunta: Como manejas secretos en Kubernetes?
Respuesta guia:
- Nada sensible en Git.
- Secret manager (Key Vault) + CSI/External Secrets.
- Rotacion periodica y RBAC minimo.

### 10) Network security
Pregunta: Como limitas superficie de ataque en Azure?
Respuesta guia:
- NSG con IPs/puertos minimos.
- Privado por defecto, publico solo lo necesario.
- Identidades administradas en vez de credenciales estaticas.

### 11) Observabilidad
Pregunta: Que metricas minimas monitoreas?
Respuesta guia:
- Golden signals: latencia, trafico, errores, saturacion.
- Disponibilidad por servicio y SLO basicos.
- Alertas accionables con contexto.

### 12) Alertas ruidosas
Pregunta: Que haces si hay demasiadas alertas?
Respuesta guia:
- Reducir ruido con thresholds y for-duration.
- Enrutamiento por severidad.
- Revisar alert fatigue y ajustar reglas.

### 13) Costos
Pregunta: Como optimizas costos sin romper estabilidad?
Respuesta guia:
- Rightsizing de VM/nodos.
- Apagado programado en entornos no productivos.
- Revisar consumo real y presupuestos.

### 14) Governance
Pregunta: Como mantienes estandares en equipo?
Respuesta guia:
- Templates, checklists y politicas en PR.
- Convenciones de naming/tagging.
- ADRs para decisiones arquitectonicas.

### 15) Senior mindset
Pregunta: Que diferencia a un DevOps senior?
Respuesta guia:
- Piensa en riesgo, operacion y negocio, no solo tooling.
- Prioriza confiabilidad, seguridad y mantenibilidad.
- Comunica trade-offs con claridad.

---

## Parte 3: Escenario Practico (Live Troubleshooting)

### Escenario
Despues de un deploy, el servicio responde 503 intermitente y sube latencia.

### Lo que debes explicar
1. Hipotesis iniciales.
2. Comandos de diagnostico.
3. Decision de mitigacion inmediata.
4. Analisis causa raiz.
5. Acciones preventivas.

### Respuesta modelo corta
"Primero verifico estado del rollout, readiness y endpoints del servicio. Reviso eventos del deployment/pod y metricas de latencia y errores en Prometheus/Grafana. Si el impacto es alto, hago rollback inmediato a la imagen estable para restaurar servicio. Luego documento causa raiz (por ejemplo probe mal calibrada o saturacion por limits bajos), aplico fix y dejo alerta/rule para detectar el patron en el futuro."

---

## Parte 4: Preguntas para hacerle al entrevistador

Haz 3-4 preguntas al final:

- Como miden disponibilidad y confiabilidad hoy?
- Tienen SLOs definidos por servicio?
- Que nivel de autonomia tiene el equipo para cambios de infraestructura?
- Cual es el mayor dolor actual en CI/CD o Kubernetes?

---

## Checklist de Preparacion Pre-Entrevista

- Puedo explicar mi arquitectura en 2 minutos.
- Puedo defender 3 decisiones tecnicas con trade-offs.
- Tengo 2 incidentes reales documentados en formato STAR.
- Puedo describir rollback end-to-end sin leer notas.
- Tengo respuestas claras para seguridad, costos y observabilidad.

---

## Simulacro Rapido (30 minutos)

- 5 min: pitch del proyecto.
- 15 min: 8 preguntas tecnicas al azar.
- 5 min: escenario de incidente.
- 5 min: preguntas al entrevistador y cierre.
