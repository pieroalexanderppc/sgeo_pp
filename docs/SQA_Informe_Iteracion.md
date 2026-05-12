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
**Informe de Resultados del Plan de Iteraciones - Aseguramiento de Calidad (SQA)**

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

**Fase/Iteración:** Incremento de Funcionalidades Base (Backend FastAPI & App Flutter)  
**Fecha de Elaboración:** 30 de Abril, 2026  

---

## 1. Objetivo del Análisis
Verificar la funcionalidad, rendimiento y calidad de los módulos desarrollados en el código de la actual iteración (App Móvil en Flutter y API en Python+MongoDB), velando por su alineación con los requerimientos del `SRS` (Software Requirements Specification) y los diagramas de arquitectura definidos en el `SAD`.

## 2. Resumen de la Revisión de Código
Se analizaron los módulos de autenticación, integración de mapas, lógica del motor de inteligencia artificial espacial (DBSCAN) y los controladores de reportes y dashboard. La revisión incluyó análisis estático de código y pruebas alfa de integración.

## 3. Matriz de Resultados y Decisiones SQA

| ID Requerimiento | Estado de Construcción | Desviaciones de Tiempo/Esfuerzo | Decisión de Aprobación SQA | ID Caso de Prueba & Tipo (Estática/Alfa) | Métricas del Módulo | Descripción de la Falla / Anomalía | Estado de Resolución |
|---|---|---|---|---|---|---|---|
| **RF001 - RF002** | Completado | Ninguna. | **Aceptado** | CP-AUT-01 (Alfa) | Densidad: 0.01 defectos/LOC | Null check temporal faltante al extraer JSON. | Corregido |
| **RF003** | Completado | Tiempo mayor por el manejo GeoJSON. | **Aceptado con retrabajo menor** | CP-MAP-01 (Estática) | Densidad: 0.05 defectos/LOC | Casteos manuales repetidos `(coords[1] as num).toDouble()` en UI. | Pasa al backlog |
| **RF004** | Completado | Desviación moderada (query `2dsphere`). | **Aceptado** | CP-VAL-01 (Alfa) | Densidad: 0.02 defectos/LOC | Cálculo de la distancia excedía 3km temporalmente. | Corregido |
| **RF005** | En progreso | Alta varianza ajustando DBSCAN (SIDPOL). | **Aceptado con retrabajo menor** | CP-ML-01 (Alfa) | Densidad: 0.08 defectos/LOC | Falta unit testing de stress; clustering masivo es lento. | Pasa al backlog |
| **RF006** | En progreso | Falta geofencing estricto móvil. | **Pospuesto** | CP-NOT-01 (Alfa) | Densidad: 0.12 defectos/LOC | Envía notificaciones a topic global (`actualizaciones`). | Pasa al backlog |
| **RF007 - RF009** | Completado | Ninguna (uso de PyMongo limpio). | **Aceptado** | CP-ADM-01 (Estática) | Densidad: 0.01 defectos/LOC | Faltaba redondear decimales. | Corregido |

## 4. Conclusiones y Plan de Acción
- **Alineación con SRS y SAD:** Se valida que el sistema cumple con la base arquitectónica propuesta (multiplataforma Flutter / backend FastAPI / MongoDB Atlas). Las métricas como los tiempos HTTPS < 300ms (RNF005) deben ser rigurosamente logueadas en el próximo sprint.
- **Arquitectura de UI (Flutter):** Se detectó mucha lógica de parseo incrustada en widgets. Se recomienda limpieza arquitectónica para separar Vistas de Capa de Datos.
- **Regla RN02 (Decaimiento Temporal):** Debe programarse y validarse en la siguiente iteración el *cron job* que remueva temporalmente los reportes ciudadanos de la Zona de Riesgo visible, una vez transcurridas 48 horas (criterio de decaimiento estadístico en caliente).

<br>

---
**Firma de Aprobación SQA**
<br><br>

______________________________________
**Piero Alexander Paja de la Cruz**  
Responsable de Calidad (Aseguramiento y Control)

*Fin del Documento de SQA.*