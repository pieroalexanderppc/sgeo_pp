<div align="center">

![Logo UPT](media/image25.png)

**UNIVERSIDAD PRIVADA DE TACNA**  
**FACULTAD DE INGENIERÍA**  
**Escuela Profesional de Ingeniería de Sistemas**  

<br>

**Proyecto:**  
**"SGEO — Sistema de Geolocalización de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial"**  

<br>

**Documento:**  
**Taller Práctico: Árbol de Decisión Estratégica - Calidad de Software**

<br>

**Curso:** Construcción De Software II  
**Docente:** Alberto Johnatan Flor Rodriguez  

**Integrante:**  
 Piero Alexander Paja de la Cruz (2020067576)  

<br>

**Tacna -- Perú**  
**2026**  

</div>

---

## 1. Objetivo
Utilizar el marco del Árbol de Decisión Estratégica para determinar el enfoque de calidad óptimo aplicable al proyecto actual de Construcción de Software II (SGEO).

A continuación se detalla el flujo de toma de decisiones teórico y su aplicación real para establecer el modelo y enfoque de calidad en el ciclo de vida de desarrollo.

---

## 2. Flujo del Árbol de Decisión (Marco Teórico)

### 2.1. Nivel de Criticidad y Regulación
**Pregunta:** ¿Es un sistema crítico para la seguridad/vida o está altamente regulado (ej. DO-178C)?

* **Sí:** 👉 **Adoptar CMMI Nivel 3+** *(Priorizar cumplimiento y auditoría exhaustiva).*  
  *Justificación:* Los sistemas críticos requieren procesos institucionalizados, alta trazabilidad y métricas de madurez organizacionales para garantizar la seguridad humana o el cumplimiento normativo.

* **No:** Continuar al paso 2.2.

### 2.2. Dimensión y Dinámica del Equipo
**Pregunta:** (Asumiendo que no es crítico/regulado) ¿El equipo de desarrollo tiene más de 5 miembros interactuando constantemente en el mismo código base?

* **Sí:** 👉 **Adoptar Agile Quality + PDCA** *(Priorizar CI/CD, revisiones por pares, automatización).*  
  *Justificación:* En equipos medianos/grandes en un entorno dinámico, se necesita mejora continua (Plan-Do-Check-Act) y prácticas ágiles para gestionar conflictos, mantener la integración continua de código y mantener una alta velocidad de entrega sin degradar la calidad.

* **No:** Continuar al paso 2.3.

### 2.3. Esfuerzo Individual o Aislado
**Pregunta:** (Asumiendo equipos pequeños o trabajo individual) ¿Es un esfuerzo en solitario o un módulo altamente aislado que requiere precisión técnica profunda?

* **Sí:** 👉 **Adoptar PSP (Personal Software Process)** *(Priorizar métricas personales y prevención temprana de inyección).*  
  *Justificación:* Para desarrolladores individuales o micro-equipos trabajando en módulos complejos, el control recae en la disciplina individual. PSP ayuda al ingeniero a medir su propio rendimiento, estimar con mayor precisión, y registrar y evitar sus errores habituales antes de la fase de compilación/pruebas.

---

## 3. Aplicación y Resolución para el Proyecto SGEO

Evaluando nuestro proyecto bajo este árbol de decisión, realizamos el siguiente análisis de flujo:

1. **¿Es un sistema crítico para la seguridad/vida o altamente regulado?**
   * **Análisis:** **NO.** Aunque SGEO es una aplicación sobre inseguridad y usa modelos predictivos de Machine Learning, no sustituye software de emergencias vitales (tipo salud aeronáutica) ni está regulada bajo estrictos estándares gubernamentales DO-178C.
   * *Avanzamos al siguiente nodo.*

2. **¿El equipo de desarrollo tiene más de 5 miembros?**
   * **Análisis:** **NO.** El desarrollo tanto del backend en Python (FastAPI/Motor IA), la base de datos en MongoDB, y la aplicación móvil en Flutter, se está realizando por un único integrante.
   * *Avanzamos al siguiente nodo.*

3. **¿Es un esfuerzo en solitario o un módulo altamente aislado que requiere precisión técnica profunda?**
   * **Análisis:** **SÍ.** Representa el trabajo y esfuerzo enteramente en solitario de un desarrollador manejando módulos técnicos avanzados, estructuras espaciales y de Machine Learning en simultáneo.

### 🏆 Conclusión Estratégica:
Para el proyecto SGEO, el enfoque a adoptar es:
👉 **Personal Software Process (PSP)** *(Priorizar métricas personales y prevención temprana de inyección de errores).*

**Plan de Acción SQA (Basado en PSP):**
* Implementar registro métrico de revisiones (como se demuestra en los Informes de Iteración).
* Registrar defectos sistemáticamente antes de integración continua y analizar cómo prevenirlos en futuras iteraciones.
* Mantener consistencia personal y disciplina en el testing de módulos complejos como los motores espaciales DBSCAN y visualizaciones de mapas en Flutter.
