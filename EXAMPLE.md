# 📱 Acees Group - Sistema de Control de Acceso NFC + IA

Sistema integral de gestión de transporte universitario y control de acceso, potenciado por Inteligencia Artificial para la optimización de rutas y horarios.

## 🏗️ Estructura del Proyecto (Deploy)

El repositorio contiene el código fuente esencial para el despliegue en producción (Railway) y la compilación de la App Móvil.

```bash
📁 Acees_Group/
├── 📱 lib/                     # Frontend: App Flutter (Dart)
├── 🌐 backend/                 # Backend Unificado
│   ├── index.js                # API Gateway + auth (Node.js)
│   ├── ml_python/              # Microservicio IA (Python FastAPI)
│   └── routes/                 # Rutas Express
├── 🐳 Dockerfile               # Configuración de Contenedor Híbrido (Node+Python)
├── ⚙️ railway.toml            # Orquestación de despliegue
└── 📦 package.json            # Dependencias Backend
```

## 🚀 Despliegue en Producción (Railway)

El sistema utiliza un **entorno híbrido** donde Node.js y Python conviven en el mismo contenedor para minimizar latencia.

- **URL Base**: `https://app-movil-control-de-acceso-production.up.railway.app`
- **Estado**: Activo (Production)

### Servicios Integrados
1.  **API Gateway (Node.js Express):** Maneja autenticación, usuarios y proxy inverso.
2.  **ML Engine (Python FastAPI):** Procesa predicciones de congestión y horarios óptimos.
3.  **Base de Datos (MongoDB Atlas):** Almacenamiento centralizado de asistencias y usuarios.

## 📋 Funcionalidades Principales

### 🧑‍🎓 Control de Acceso & Usuarios
- Autenticación segura vía JWT.
- Gestión de roles (Admin/Estudiante).
- Historial de accesos en tiempo real.

### 🤖 Inteligencia Artificial (ML)
- **Predicción de Horas Pico:** Análisis histórico para evitar aglomeraciones.
- **Recomendación de Flota:** Cálculo automático de buses necesarios según demanda.
- **Detección de Anomalías:** Monitoreo de patrones irregulares de asistencia.

### 📱 Aplicación Móvil (Flutter)
- Arquitectura MVVM (Model-View-ViewModel).
- Modo Offline con sincronización automática.
- Visualización de gráficas y reportes predictivos.

## 🛠️ Tecnologías

| Componente | Tecnología | Uso |
|------------|------------|-----|
| **Frontend** | Flutter (Dart) | App iOS/Android |
| **Backend 1** | Node.js (Express) | API REST, Auth, Proxy |
| **Backend 2** | Python (FastAPI) | Modelos ML, Pandas, Scikit-learn |
| **DB** | MongoDB Atlas | Persistencia de datos |
| **Infra** | Docker + Railway | CI/CD y Alojamiento |

## 🔧 Configuración Rápida

### Requisitos Previos
- Flutter SDK
- Node.js 18+
- Python 3.10+
- Cuenta en MongoDB Atlas & Railway

### Variables de Entorno (Producción)
```env
# Base de Datos
MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/ASISTENCIA

# Configuración del Servicio
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Microservicio ML (Interno)
PYTHON_SERVICE_URL=http://localhost:8000
```

---

**Desarrollado para la gestión eficiente del transporte universitario.**
© 2026 Acees Group
