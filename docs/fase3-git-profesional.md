# 📘 FASE 3 — Control de Versiones Profesional

> Dominar Git a nivel DevOps Senior

---

## 🎯 Objetivo

Aprender conceptos avanzados de Git que un DevOps Senior debe dominar.

---

## 1️⃣ REBASE vs MERGE

### ¿Cuál es la diferencia?

**MERGE:**
```
main:     A---B---C---F (merge commit)
                     /
feature:       D---E
```
- Crea un commit de merge
- Mantiene el historial completo
- Historial "sucio" con muchas ramas

**REBASE:**
```
main:     A---B---C---D'---E'
```
- Reescribe el historial
- Historial lineal y limpio
- Los commits de feature se "mueven" encima de main

---

### ¿Cuándo usar cada uno?

**USA MERGE cuando:**
- Trabajas en equipo en la misma rama
- Quieres preservar el historial exacto
- Es una feature importante que quieres marcar

**USA REBASE cuando:**
- Actualizas tu rama local con cambios de main
- Quieres limpiar commits antes de PR
- Trabajas solo en tu rama

---

### ⚠️ REGLA DE ORO

**NUNCA hagas rebase en ramas públicas/compartidas**

Si otros desarrolladores tienen la rama, usar rebase causará conflictos.

---

## 2️⃣ CONVENTIONAL COMMITS

### ¿Qué es?

Estándar para escribir mensajes de commit que permiten automatización.

### Formato

```
<tipo>(<scope>): <descripción corta>

[cuerpo opcional - explica el QUÉ y POR QUÉ]

[footer opcional - breaking changes, issues]
```

### Tipos principales

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| `feat` | Nueva funcionalidad | `feat(api): agregar endpoint de login` |
| `fix` | Corrección de bug | `fix(auth): corregir validación de email` |
| `docs` | Documentación | `docs(readme): actualizar guía de instalación` |
| `style` | Formato (no afecta código) | `style: formatear con prettier` |
| `refactor` | Refactorización | `refactor(db): optimizar queries` |
| `test` | Tests | `test(api): agregar tests de integración` |
| `chore` | Tareas de mantenimiento | `chore(deps): actualizar dependencias` |
| `ci` | CI/CD | `ci: agregar workflow de deploy` |

### Ejemplo completo

```bash
git commit -m "feat(vm): agregar auto-scaling

Implementa auto-scaling basado en CPU para VMs.
Escala entre 2-10 instancias cuando CPU > 70%.

Closes #123"
```

### ¿Por qué importa en DevOps?

✅ Pipelines pueden detectar el tipo y actuar diferente  
✅ Genera CHANGELOGs automáticamente  
✅ Versionado semántico automático (feat = minor, fix = patch)  
✅ Mejor comunicación en el equipo  

---

## 3️⃣ GIT HOOKS

### ¿Qué son?

Scripts que se ejecutan automáticamente en eventos de Git.

### Hooks más útiles en DevOps

| Hook | Cuándo se ejecuta | Uso común |
|------|-------------------|-----------|
| `pre-commit` | Antes de crear commit | Linters, formateo |
| `commit-msg` | Al escribir mensaje | Validar formato |
| `pre-push` | Antes de push | Ejecutar tests |
| `post-merge` | Después de merge | Instalar dependencias |

---

### 🧪 PRÁCTICA: Pre-commit Hook

**Ubicación:** `.git/hooks/pre-commit`

**Nuestro hook implementado:**

```bash
#!/bin/bash

echo "🔍 Ejecutando validaciones pre-commit..."

# Verificar que no haya archivos grandes
large_files=$(find . -type f -size +10M 2>/dev/null | grep -v ".git")
if [ ! -z "$large_files" ]; then
    echo "❌ Error: Archivos muy grandes detectados:"
    echo "$large_files"
    exit 1
fi

# Verificar que no haya credenciales reales (excluir docs)
if git diff --cached --name-only | grep -v "docs/" | xargs git diff --cached | grep -iE "(password|secret_key|api_key.*=)" > /dev/null 2>&1; then
    echo "⚠️  Advertencia: Posibles credenciales detectadas en código"
    exit 1
fi

echo "✅ Validaciones pasadas"
exit 0
```

**¿Qué hace?**
1. Detecta archivos mayores a 10MB
2. Busca posibles credenciales en el código
3. Bloquea el commit si encuentra problemas

---

### Saltar hooks temporalmente

```bash
git commit -m "mensaje" --no-verify
```

Útil cuando el hook da falsos positivos.

---

## 🎓 Conceptos aprendidos

✅ **Rebase** - Para historial limpio (solo en ramas locales)  
✅ **Merge** - Para preservar historial completo  
✅ **Conventional Commits** - Para automatización y comunicación  
✅ **Git Hooks** - Para validaciones automáticas  

---

## 📚 Comandos útiles

### Ver historial gráfico
```bash
git log --oneline --graph --all
```

### Rebase interactivo (limpiar commits)
```bash
git rebase -i HEAD~3
```

### Ver diferencias antes de commit
```bash
git diff --cached
```

### Listar hooks disponibles
```bash
ls -la .git/hooks/
```

---

## ⏭️ Próxima fase

**FASE 4 - CI/CD Profesional en Azure**

Donde aplicaremos estos conceptos en pipelines reales.

---

**Completado:** 21 Feb 2026 ✅
