# 📱 SGEO - Sistema de Geolocalización de Inseguridad Ciudadana

Aplicación móvil orientada a la participación ciudadana para registrar, visualizar y reportar zonas de inseguridad en tiempo real.

## 📂 Estructura del Proyecto

El repositorio contiene el código fuente esencial para el despliegue de la API y la compilación de la App Móvil.

```bash
📦 SGEO_PP/
├── 📱 lib/                     # Frontend: App Flutter (Dart)
├── 🌍 backend/                 # Backend (Python FastAPI)
│   ├── main.py                 # API REST de reportes de seguridad
│   └── requirements.txt        # Dependencias Python
└── ⚙️ pubspec.yaml             # Orquestación de dependencias móviles
```

## 🚀 Despliegue en Producción (Railway)

El sistema utiliza **Python FastAPI** como backend ágil conectado a una base de datos en tiempo real.

- **URL Base Backend**: `https://sgeo-backend-production.up.railway.app` 
- **Estado**: Activo (Production)

### Servicios Integrados
1.  **Backend API (Python FastAPI):** Procesamiento de reportes ciudadanos e historial de usuario.
2.  **Base de Datos (MongoDB):** Almacenamiento centralizado de reportes geolocalizados y usuarios.

## 📋 Funcionalidades Principales

### 🗺️ Mapas y Geolocalización Integrada
- Mapas dinámicos centrados en el usuario.
- Extracción precisa de latitud y longitud.

### 🚨 Sistema de Reportes Ciudadanos
- Creación rápida de incidentes (Punteo/Arrebato, Hurto, Robo).
- Autocompletado de coordenadas, omitiendo el ingreso manual de direcciones.
- Historial personal de reportes sincronizado en tiempo real con el backend.

### 🦺 Módulos de Prevención
- Rutas y alertas comunitarias.
- Interfaz móvil intuitiva bajo una arquitectura limpia (Clean Architecture).

## 🛠️ Tecnologías

| Componente | Tecnología | Uso |
|------------|------------|-----|
| **Frontend** | Flutter (Dart) | App iOS/Android |
| **Backend** | Python (FastAPI) | API REST y gestión de datos |
| **Data** | Pydantic / bson | Validación y estructuración |
| **DB** | MongoDB | Base de datos NoSQL documental |

## 🔧 Configuración Rápida

### Requisitos Previos
- Flutter SDK (Última versión estable)
- Python 3.10+
- Servidor de base de datos MongoDB y credenciales de acceso

### Despliegue Local del Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

---

**Desarrollado para mejorar la seguridad a través de la participación ciudadana.**
