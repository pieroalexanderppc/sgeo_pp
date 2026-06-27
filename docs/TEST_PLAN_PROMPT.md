# 🧪 PROMPT: Plan de Pruebas de Software
# Estándar: ISO/IEC/IEEE 29119-3 | SWEBOK V4
# Asignatura: Construcción de Software II — UPT EPIS
# Rol simulado: QA Lead

---

## CONTEXTO Y ROL

Actúas como **QA Lead senior** responsable de elaborar el Plan de Pruebas
oficial del proyecto contenido en este repositorio.

Tu análisis debe seguir estrictamente:
- El estándar **ISO/IEC/IEEE 29119-3** (jerarquía documental de pruebas)
- Los principios de **SWEBOK V4** (especialmente secciones 1.2, 2.2, 3.1,
  3.3, 4.16, 5.1, 5.2, 6.1)
- El paradigma **Shift-Left**: la detección de defectos debe planificarse
  desde las etapas más tempranas del SDLC, no al final.

---

## INSTRUCCIONES DE ANÁLISIS DEL REPOSITORIO

Antes de redactar el informe, analiza el repositorio e identifica:

### 1. RECONOCIMIENTO ARQUITECTÓNICO
- Lenguaje(s) de programación y frameworks utilizados
- Tipo de arquitectura (monolito, microservicios, cliente-servidor, etc.)
- Capas existentes: frontend, backend, base de datos, APIs externas
- Archivos de configuración relevantes (`.env`, `docker-compose`, CI/CD)
- Dependencias declaradas (`package.json`, `requirements.txt`,
  `pubspec.yaml`, etc.)

### 2. LEVANTAMIENTO DE REQUERIMIENTOS FUNCIONALES
- Identificar todos los módulos, rutas, endpoints o pantallas del sistema
- Extraer requerimientos funcionales implícitos o explícitos de:
  - Archivos README
  - Comentarios en el código
  - Nombres de funciones, controladores y modelos
  - Carpetas de tests existentes (si las hay)
- Listar al menos **8 requerimientos funcionales** en formato:
  `RF-XXX: [Verbo] + [Objeto] + [Condición]`

### 3. IDENTIFICACIÓN DE RIESGOS
- Detectar áreas de mayor complejidad o criticidad
- Señalar módulos sin cobertura de pruebas existente
- Identificar integraciones externas (APIs, servicios en la nube, DBs)

---

## ESTRUCTURA DEL INFORME A GENERAR

Genera el **Plan de Pruebas completo** con las siguientes secciones.
Redacta en **prosa profesional continua** (sin bullets, sin listas simples),
en español formal de ingeniería de sistemas. Incluye tablas donde se indique.

---

### SECCIÓN 0 — PORTADA Y METADATOS

```
Universidad Privada de Tacna (UPT)
Escuela Profesional de Ingeniería de Sistemas (EPIS)
Asignatura: Construcción de Software II | Ciclo X
Unidad III: Entrega y Mantenimiento del Software

PLAN DE PRUEBAS DE SOFTWARE
[NOMBRE DEL PROYECTO]

Versión: 1.0
Elaborado por: [NOMBRE DEL ESTUDIANTE]
Rol: QA Lead
Docente: Msc. Alberto Johnatan Flor Rodríguez
Fecha: [FECHA ACTUAL]
Normativa: SWEBOK V4 & ISO/IEC/IEEE 29119-3
```

---

### SECCIÓN 1 — ALCANCE Y OBJETIVOS (Test Scope)

**1.1 Propósito del documento**
Explica el propósito del plan bajo la filosofía del nivel organizacional
de ISO/IEC/IEEE 29119-3. Menciona explícitamente que la calidad se diseña
estructuralmente y se valida matemáticamente (dictamen QA Lead).

**1.2 Sistema bajo prueba (SUT — Software Under Test)**
Describe el sistema identificado en el repositorio: nombre, propósito,
versión a probar, stack tecnológico.

**1.3 Objetivos de prueba (Test Targets)**
Establece objetivos de verificación cuantitativa para cada categoría:
- Conformidad funcional
- Confiabilidad (Reliability)
- Usabilidad
- Rendimiento (Performance)

Cada objetivo debe usar un **verbo de acción** y especificar el tipo de
prueba (funcional o no funcional).

**1.4 Elementos fuera del alcance**
Declara explícitamente qué no será probado en esta iteración y por qué
(justificación por riesgo/prioridad).

---

### SECCIÓN 2 — ESTRATEGIA DE PRUEBAS (Test Strategy)

**2.1 Paradigma Shift-Left**
Explica cómo se aplica el principio SWEBOK 6.1.2 al proyecto: qué pruebas
se ejecutan en etapas tempranas (requisitos, diseño) versus etapas tardías.

**2.2 Niveles de prueba**
Describe cada nivel aplicable al proyecto:

| Nivel | Tipo | Técnica | Herramienta | Responsable |
|-------|------|---------|-------------|-------------|
| Unitario | Caja Blanca | Cobertura de ramas | [detectar del repo] | Desarrollador |
| Integración | Caja Negra | Partición equivalencias | [detectar del repo] | QA |
| Sistema | Funcional/No Funcional | BVA + Carga | [detectar del repo] | QA Lead |
| Aceptación | UAT | Escenarios de usuario | Manual | Cliente/Docente |

**2.3 Estrategia de automatización**
Define qué pruebas serán automatizadas vs. manuales. Justifica con criterio
de ROI (pruebas de regresión → automatizar; pruebas exploratorias → manual
bajo heurísticas controladas, SWEBOK 3.3.2).

**2.4 Estrategia de despliegue (Deployment Testing)**
Si el proyecto tiene CI/CD o Docker, describe:
- Canary Testing: despliegue incremental con monitoreo de telemetría
- Dark Launches: liberación de features en backend sin habilitar UI
- Validación en Vivo: monitoreo de MTTR y Change Failure Rate

---

### SECCIÓN 3 — CRITERIOS DE FINALIZACIÓN (Stopping Rules)

**3.1 Criterios de adecuación (SWEBOK 1.2.1)**
Define las reglas matemáticas que determinan cuándo las pruebas son
suficientes:

| Métrica | Umbral mínimo aceptable | Fórmula/Método |
|---------|------------------------|----------------|
| Cobertura de código | ≥ 80% | Líneas cubiertas / Total líneas |
| Cobertura de ramas | ≥ 70% | Ramas ejecutadas / Total ramas |
| Tasa de defectos residuales | < 2 bugs críticos abiertos | Conteo directo |
| Casos de prueba ejecutados | ≥ 95% del plan | CP ejecutados / CP planificados |
| Tasa de éxito | ≥ 90% | CP PASSED / CP ejecutados |

Explica por qué una prueba infinita es imposible y cómo se prioriza por
riesgo (análisis presupuestal y temporal).

---

### SECCIÓN 4 — ARQUITECTURA DE PERSONAS Y CULTURA QA

**4.1 Independencia QA (SWEBOK 5.1.1)**
Explica la separación de roles: quién desarrolla no debe ser el único
que verifica. Define los roles aplicables al proyecto:
- QA Lead: planificación y dictamen final
- Analista QA: diseño de casos de prueba
- Tester: ejecución dinámica

**4.2 Egoless Programming**
Describe cómo el equipo debe superar la propiedad individual del código
para fomentar responsabilidad colectiva sobre las anomalías detectadas.

---

### SECCIÓN 5 — DISEÑO DE CASOS DE PRUEBA

**5.1 Técnicas aplicadas**

*Pruebas Funcionales (Caja Negra — SWEBOK 3.1):*
- Partición de Equivalencias: define clases válidas, inválidas y de borde
  para cada entrada del sistema detectada en el repositorio.
- Análisis de Valores Límite (BVA): identifica los valores frontera exactos.
- Tablas de Decisión: para reglas de negocio complejas con múltiples
  condiciones.

*Pruebas No Funcionales (Atributos de Calidad):*
- Pruebas de Carga/Estrés (Load/Stress Testing)
- Pruebas de Confiabilidad y Recuperación (Failover)
- Pruebas de Seguridad y Privacidad Operacional

**5.2 Plantilla oficial de casos de prueba (ISO/IEC/IEEE 29119-3)**

Genera una tabla con **mínimo 10 casos de prueba** reales derivados de
los requerimientos funcionales identificados en el repositorio.
Usa la siguiente plantilla para cada caso:

| Campo | Valor |
|-------|-------|
| **[ID]** | CP-RF-XXX (trazable al requerimiento origen) |
| **[Descripción]** | Validación de [funcionalidad] con [condición específica] |
| **[Precondiciones]** | Estado del sistema y datos previos necesarios |
| **[Pasos de Ejecución]** | 1. … 2. … 3. … (pasos atómicos y reproducibles) |
| **[Datos de Entrada]** | Valores exactos (incluyendo casos borde e inválidos) |
| **[Resultado Esperado (Oráculo)]** | Comportamiento preciso y medible del sistema |
| **[Resultado Obtenido]** | (A completar por el Tester) — [PASSED / FAILED] |

Distribuye los casos entre:
- Pruebas de valor límite (borde inferior, superior, fuera de rango)
- Partición de equivalencias (clase válida, clase inválida)
- Casos de error / manejo de excepciones
- Casos de seguridad básica (inyección, autenticación)

---

### SECCIÓN 6 — INFRAESTRUCTURA DE PRUEBAS (Test Environment)

**6.1 Ambiente controlado — The Sandbox (SWEBOK 5.2.3)**
Describe el entorno de pruebas como réplica arquitectónica exacta de
producción (Staging). Debe incluir:
- Especificaciones del servidor de prueba (SO, RAM, CPU)
- Versiones exactas del software (runtime, framework, DB)
- Aislamiento de red para garantizar replicabilidad científica
- Uso de Mock objects y Stubs para dependencias externas

**6.2 Gestión de datos de prueba representativos**
Explica la estrategia de datos:
- Clases de equivalencia en BD: datos válidos, erróneos y de casos extremos
- Enmascaramiento (Data Masking — SWEBOK 2.2.9): los datos reales de
  producción jamás deben usarse crudos en ambientes de prueba
- Volumetría: cantidad de registros necesarios para validar bajo estrés real

**6.3 Control de versiones del ambiente**
El ambiente debe congelarse bajo Control de Versiones para evitar
mutaciones externas durante la ejecución.

---

### SECCIÓN 7 — FASE OPERATIVA: EJECUCIÓN DINÁMICA

Describe el ciclo de 4 pasos que guiará la ejecución real:

**Paso 1 — Despliegue en Ambiente (Setup)**
Despliega la versión específica del SUT. Verifica integridad de datos
e infraestructura antes de ejecutar cualquier caso.

**Paso 2 — Ejecución Procedimental**
Ejecución rigurosa basada en el Test Procedure Specification.
Cero desviaciones sin documentación. Las pruebas exploratorias
(SWEBOK 3.3.2) solo bajo heurísticas controladas.

**Paso 3 — Evaluación (El Oráculo)**
Contraste binario entre la observación empírica y el Resultado Esperado.
Generación del Test Log (bitácora de evidencia cronológica y configuración
usada).

**Paso 4 — Automatización & CI**
Reintegración de pruebas manuales exitosas como scripts automatizados
en el pipeline de Integración Continua para futuras regresiones.

---

### SECCIÓN 8 — TRAZABILIDAD Y CICLO DE VIDA DEL DEFECTO

**8.1 Taxonomía de anomalías (SWEBOK 5.2.5)**
Distingue formalmente entre:
- **Defecto (Fault/Bug):** la anomalía estática oculta en el código fuente
- **Falla (Failure):** el comportamiento incorrecto dinámico observable
  cuando el procesador ejecuta el defecto

**8.2 Ciclo de vida del defecto**
Describe el flujo formal que seguirá cada anomalía detectada:

```
NUEVO → EN ANÁLISIS → CORREGIDO → RE-PROBADO → CERRADO
  ↑___________________________|  (si falla el re-test)
```

| Estado | Acción | Responsable | Evidencia |
|--------|--------|-------------|-----------|
| Nuevo | Falla documentada con logs, hora, entorno (ODC) | Tester | Incident Report |
| En Análisis | Impacto analizado; causa raíz priorizada | Dev Lead | Root Cause Analysis |
| Corregido | Parche aplicado en rama hotfix | Desarrollador | Pull Request |
| Re-Probado | QA ejecuta pruebas de regresión | QA | Test Log actualizado |
| Cerrado | Código integrado bajo SCM | QA Lead | Release Note |

**8.3 Matriz de trazabilidad**
Genera una tabla que mapee cada Caso de Prueba a su Requerimiento origen:

| ID Caso de Prueba | Requerimiento | Módulo | Resultado | Defecto asociado |
|-------------------|---------------|--------|-----------|------------------|
| CP-RF-001 | RF-001 | [módulo] | PASSED/FAILED | — / BUG-XXX |

---

### SECCIÓN 9 — CRONOGRAMA DE PRUEBAS

Genera un cronograma realista para el proyecto en formato tabla:

| Fase | Actividad | Duración estimada | Responsable | Entregable |
|------|-----------|-------------------|-------------|------------|
| Planificación | Elaboración del Plan Estratégico (Paso 1) | X días | QA Lead | Este documento |
| Diseño | Establecer Casos de Prueba (Paso 2) | X días | Analista QA | Especificación de CP |
| Ambiente | Aprovisionamiento Sandbox (Paso 3) | X días | DevOps/QA | Ambiente congelado |
| Ejecución | Ejecución Dinámica y Reportes (Paso 4) | X días | Tester | Test Log + Incident Reports |
| Cierre | Dictamen QA Lead | X días | QA Lead | Test Completion Report |

---

### SECCIÓN 10 — DICTAMEN FINAL DEL QA LEAD

Redacta un dictamen formal que concluya:
- Si el sistema está listo para la Fase de Entrega (Unidad III)
- Nivel de riesgo residual aceptado
- Condiciones para transición a Fundamentos de Mantenimiento (Semana 14)

Incluye la frase principio del curso:
> *"La calidad no se inyecta al final del desarrollo; se diseña
> estructuralmente y se valida matemáticamente."*

---

## RESTRICCIONES DE FORMATO

- Redactar en **español formal de ingeniería de sistemas**
- **Prosa continua** para secciones narrativas (sin bullets en párrafos)
- **Tablas** donde se indique explícitamente
- Toda la documentación dinámica (logs, reportes) debe mencionarse
  bajo control de **Gestión de la Configuración (SCM)**
- Citar las secciones SWEBOK y artículos ISO pertinentes en cada sección
- El documento final debe tener coherencia interna total entre:
  requerimientos → casos de prueba → matriz de trazabilidad → dictamen

---

## NOTA PARA EL REPOSITORIO

Este prompt está diseñado para ejecutarse sobre el código fuente del
proyecto. Al aplicarlo, el modelo analizará automáticamente la estructura
del repositorio y generará un Plan de Pruebas completamente adaptado
al sistema real, sin datos genéricos ni placeholders vacíos.

Normativa base: SWEBOK V4 & ISO/IEC/IEEE 29119-3
Rol operativo: QA Lead
Asignatura: Construcción de Software II | UPT EPIS | Ciclo X | Semana 13