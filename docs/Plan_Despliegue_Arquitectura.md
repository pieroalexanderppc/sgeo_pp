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
**Plan de Despliegue y Áreas de Sistemas (Misión del Arquitecto)**

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

## Objetivo Procedimental (Semana 9)
Elaborar el plan de despliegue y definir las áreas y ambientes de sistemas del proyecto SGEO, asumiendo una mentalidad defensiva en el diseño de infraestructura ("asumiendo que el despliegue fallará y planificando SQA para evitarlo").

---

## 1. Definición de Ambientes y Matriz de Riesgo

Se ha documentado la separación lógica de los entornos para el ecosistema de SGEO (Backend FastAPI + MongoDB, y Frontend Flutter). 

| Ambiente | Descripción | Nivel de Riesgo | Estrategia de Mitigación en Despliegue |
| :--- | :--- | :---: | :--- |
| **Desarrollo (Dev)** | Ejecución en local (Emulador Android / localhost:8000 para API). Uso de base de datos MongoDB (rama desarrollo) e importación manual (ej. `import_arcgis_data.py`). | **Bajo** | Errores aislados, no afectan a usuarios. Pruebas unitarias iterativas (PSP). |
| **Calidad (QA / Staging)** | Despliegue empaquetado local para Alpha Testing (`flutter build apk`). Conexión a la base de datos de pruebas para validar los reportes ciudadanos y la IA. | **Medio** | Pruebas de integración sobre el modelo espacial (DBSCAN) y verificación de interfaz (Widgets sin overflow). |
| **Producción (Prod)** | Backend alojado en la nube (definido vía `Procfile` y `runtime.txt`) con MongoDB Atlas. Aplicación distribuida como Release. | **Alto** | Monitoreo activo, versionamiento estricto en el repositorio, respaldos semanales de BD. |

---

## 2. Criterios de Testabilidad

### 2.1. Modularidad
El código fuente demuestra una alta cohesión y bajo acoplamiento:
* **En el Frontend (Flutter):** El proyecto sigue una clara delimitación en `lib/` separando `core/` (servicios, widgets comunes como `safety_score_gauge.dart`), `features/` y `roles/` (agrupando vistas de `police` y `user`). Esto permite aislar y testear piezas individuales por cada rol sin romper el resto de la app.
* **En el Backend (Python):** Se independizan módulos críticos, como `firebase_service.py` (Manejo de Push) y la lógica matemática/predictiva (`motor_ia_zonas_riesgo.py`, `predictive_context_engine.py`) separados del enrutador central `main.py`.

### 2.2. Observabilidad
* Manejo extensivo de bloques `try-except` en FastAPI con retorno detallado del error al cliente vía HTTP 500 y logs internos por consola, permitiendo la visibilidad de qué nodo de la API falló.
* En Flutter, registro de errores vía `debugPrint()`, capturando excepciones si los JSON generados por el backend (ej. fallos en Puntos Historiales) no concuerdan (visibilidad en terminal logcat).

---

## 3. Estructura del Plan (Lienzo de Despliegue)

### 3.1. Roles
* **Arquitecto de Software / Ingeniero SQA:** Piero Paja (Encargado de la supervisión, despliegue del entorno y habilitación de MongoDB y API).

### 3.2. Herramientas SWEBOK
* **Gestión de Configuración:** Git, GitHub (Versionamiento y control de ramas).
* **Construcción (Build):** Entorno y CLI de Flutter y Python (`requirements.txt`).
* **Despliegue Técnico:** Plataformas PaaS/SaaS vinculadas por `Procfile` para el backend. Ejecución en dispositivos reales usando modo release de Flutter.

### 3.3. Criterios Go / No-Go
* **Criterios GO (Aprobado):** 
  * Los Endpoints HTTP retornan código 200/201 sistemáticamente en las pruebas.
  * La app móvil no sufre cierres inesperados al visualizar el mapa denso de calor (DBSCAN).
  * Los JWT / validaciones de Firebase funcionan correctamente.
* **Criterios NO-GO (Rechazado):** 
  * El motor de IA genera desbordamiento de memoria por las consultas (más de 1s de respuesta).
  * Falla la visualización de responsividad de widgets críticos.

### 3.4. Plan de Rollback (Plan de Reversión)
En caso de fallo general durante el pase a Producción:
* **Base de Datos:** Al contar con colecciones MongoDB, revertir a los *snapshots* de respaldo del día anterior.
* **Backend:** Ejecutar reversión local vía Git (`git revert <commit_hash>`) y desplegar inmediatamente la rama estable previa para restaurar las rutas caídas.
* **Frontend:** Mantener o instar la instalación de la versión de la APK de producción anterior hasta que los arreglos sean aprobados por QA.