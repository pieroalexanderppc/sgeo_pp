---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-family: 'Segoe UI', sans-serif;
    background-color: #ffffff;
    color: #1a1a2e;
    padding: 50px 70px;
  }
  section.lead {
    background: linear-gradient(135deg, #0f3460 0%, #16213e 60%, #1a1a2e 100%);
    color: #ffffff;
    text-align: center;
    justify-content: center;
  }
  section.lead h1 {
    font-size: 72px;
    font-weight: 800;
    color: #00d4aa;
    margin-bottom: 10px;
    letter-spacing: 4px;
  }
  section.lead h2 {
    font-size: 20px;
    font-weight: 400;
    color: #a8d8ea;
    max-width: 700px;
    margin: 0 auto 30px;
    line-height: 1.5;
  }
  section.lead p {
    font-size: 13px;
    color: #7f8c8d;
    line-height: 1.8;
  }
  section.lead .badge {
    display: inline-block;
    background: rgba(0,212,170,0.15);
    border: 1px solid #00d4aa;
    color: #00d4aa;
    padding: 6px 18px;
    border-radius: 20px;
    font-size: 13px;
    margin-bottom: 20px;
  }
  h1 {
    font-size: 38px;
    font-weight: 700;
    color: #0f3460;
    border-left: 5px solid #00d4aa;
    padding-left: 18px;
    margin-bottom: 30px;
  }
  h2 {
    font-size: 22px;
    font-weight: 600;
    color: #16213e;
    margin-bottom: 16px;
  }
  ul {
    list-style: none;
    padding: 0;
  }
  ul li {
    padding: 8px 0 8px 28px;
    position: relative;
    font-size: 17px;
    color: #2c3e50;
    line-height: 1.5;
    border-bottom: 1px solid #f0f0f0;
  }
  ul li:before {
    content: "▸";
    position: absolute;
    left: 0;
    color: #00d4aa;
    font-weight: bold;
  }
  .cols {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
    margin-top: 10px;
  }
  .card {
    background: #f8fbff;
    border: 1px solid #e0eaf5;
    border-radius: 12px;
    padding: 22px 24px;
  }
  .card h3 {
    font-size: 16px;
    font-weight: 700;
    color: #0f3460;
    margin-bottom: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .card ul li {
    font-size: 15px;
    border-bottom: none;
    padding: 5px 0 5px 22px;
  }
  .highlight-box {
    background: linear-gradient(135deg, #e8f8f5, #d5f0ea);
    border-left: 4px solid #00d4aa;
    border-radius: 8px;
    padding: 20px 24px;
    margin-top: 20px;
    font-size: 16px;
    color: #1a5276;
    line-height: 1.7;
  }
  .problem-box {
    background: #fff5f5;
    border-left: 4px solid #e74c3c;
    border-radius: 8px;
    padding: 20px 24px;
    margin-bottom: 16px;
  }
  .problem-box p {
    margin: 0;
    font-size: 16px;
    color: #922b21;
    font-weight: 500;
  }
  .solution-box {
    background: #f0fff4;
    border-left: 4px solid #27ae60;
    border-radius: 8px;
    padding: 20px 24px;
    margin-bottom: 16px;
  }
  .solution-box p {
    margin: 0;
    font-size: 16px;
    color: #1e8449;
    font-weight: 500;
  }
  .arch-layer {
    background: #f8fbff;
    border: 1px solid #dce8f5;
    border-radius: 10px;
    padding: 14px 20px;
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .arch-icon {
    font-size: 26px;
    min-width: 36px;
  }
  .arch-label {
    font-size: 15px;
    font-weight: 700;
    color: #0f3460;
  }
  .arch-desc {
    font-size: 13px;
    color: #7f8c8d;
  }
  .flow-step {
    display: flex;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 14px;
  }
  .flow-num {
    background: #0f3460;
    color: white;
    border-radius: 50%;
    width: 30px;
    height: 30px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: 700;
    flex-shrink: 0;
  }
  .flow-text {
    font-size: 16px;
    color: #2c3e50;
    padding-top: 4px;
    line-height: 1.5;
  }
  .metric-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 16px;
    margin-top: 20px;
  }
  .metric-card {
    background: #0f3460;
    border-radius: 12px;
    padding: 20px 16px;
    text-align: center;
  }
  .metric-card .num {
    font-size: 28px;
    font-weight: 800;
    color: #00d4aa;
  }
  .metric-card .label {
    font-size: 13px;
    color: #a8d8ea;
    margin-top: 4px;
  }
  .tech-pill {
    display: inline-block;
    background: #eaf4ff;
    border: 1px solid #b3d4f0;
    color: #1a5276;
    padding: 5px 14px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
    margin: 4px;
  }
  .role-card {
    border-radius: 10px;
    padding: 16px 18px;
    margin-bottom: 10px;
  }
  .role-card.ciudadano { background: #eaf6fb; border-left: 4px solid #3498db; }
  .role-card.policia   { background: #fef9e7; border-left: 4px solid #f39c12; }
  .role-card.admin     { background: #eafaf1; border-left: 4px solid #27ae60; }
  .role-card h3 { font-size: 15px; font-weight: 700; margin-bottom: 6px; }
  .role-card.ciudadano h3 { color: #1a5276; }
  .role-card.policia h3   { color: #784212; }
  .role-card.admin h3     { color: #1e8449; }
  .role-card p { font-size: 13px; color: #555; margin: 0; }
  .tag-row { margin-top: 24px; }
  footer {
    font-size: 12px;
    color: #bdc3c7;
  }
  section::after {
    font-size: 12px;
    color: #bdc3c7;
  }
---

<!-- _class: lead -->

<div class="badge">Construccion de Software II · UPT · 2026</div>

# SGEO

## Sistema de Geolocalizacion de Inseguridad Ciudadana con Machine Learning Predictivo y Espacial

Piero Alexander Paja de la Cruz — 2020067576
Docente: Alberto Johnatan Flor Rodriguez

---

# El Problema

<div class="problem-box"><p>⚠ La seguridad ciudadana en Tacna opera de forma reactiva: la Policia actua despues de que el incidente ocurre.</p></div>

<div class="cols">
<div class="card">
<h3>Brechas actuales</h3>
<ul>
<li>Respuesta tardia ante incidentes</li>
<li>Data historica criminalistica sin explotar</li>
<li>Sin visibilidad de zonas de riesgo en tiempo real</li>
<li>No existe canal unificado ciudadano-policia</li>
</ul>
</div>
<div class="card">
<h3>Consecuencias</h3>
<ul>
<li>Patrullaje ineficiente y costoso</li>
<li>Ciudadano sin herramientas de alerta temprana</li>
<li>Subuso de registros SIDPOL disponibles</li>
<li>Baja percepcion de seguridad</li>
</ul>
</div>
</div>

---

# La Solución: SGEO

<div class="solution-box"><p>✅ Una plataforma civico-policial que convierte datos historicos y reportes ciudadanos en prevencion activa mediante geolocalizacion e Inteligencia Artificial.</p></div>

<div class="cols">
<div class="card">
<h3>Que hace</h3>
<ul>
<li>Reporte geolocalizado de incidentes</li>
<li>Validacion policial en tiempo real</li>
<li>Deteccion de zonas de riesgo con IA</li>
<li>Alertas push preventivas</li>
<li>Dashboard predictivo para gestion</li>
</ul>
</div>
<div class="card">
<h3>Para quien</h3>
<ul>
<li>Ciudadanos: reportar y recibir alertas</li>
<li>Policia: validar y priorizar respuesta</li>
<li>Admins: analizar y planificar</li>
<li>Municipalidad: insumos de politica publica</li>
</ul>
</div>
</div>

---

# Arquitectura del Sistema

<div class="arch-layer">
<div class="arch-icon">📱</div>
<div>
<div class="arch-label">Capa de Presentacion — Flutter</div>
<div class="arch-desc">App movil multiplataforma: mapa ciudadano · vista policia · dashboard admin · autenticacion por rol</div>
</div>
</div>
<div class="arch-layer">
<div class="arch-icon">⚙️</div>
<div>
<div class="arch-label">Capa de Negocio — FastAPI + Uvicorn (ASGI)</div>
<div class="arch-desc">Autenticacion JWT/RBAC · gestion de reportes · motor IA espacial · motor IA temporal · BackgroundTasks</div>
</div>
</div>
<div class="arch-layer">
<div class="arch-icon">🗄️</div>
<div>
<div class="arch-label">Capa de Datos — MongoDB Atlas</div>
<div class="arch-desc">Indices 2dsphere · colecciones: usuarios, reportes, incidentes, zonas_riesgo, alertas, estadisticas_sidpol</div>
</div>
</div>
<div class="arch-layer">
<div class="arch-icon">🔔</div>
<div>
<div class="arch-label">Servicios Cloud — Firebase Cloud Messaging</div>
<div class="arch-desc">Alertas push preventivas por geofencing en zonas de riesgo detectadas</div>
</div>
</div>

---

# Flujo de Datos Clave

<div class="flow-step"><div class="flow-num">1</div><div class="flow-text">Ciudadano reporta incidente con GPS desde la app movil</div></div>
<div class="flow-step"><div class="flow-num">2</div><div class="flow-text">Backend guarda el reporte en estado <strong>pendiente</strong></div></div>
<div class="flow-step"><div class="flow-num">3</div><div class="flow-text">Policia en radio de 3 km <strong>valida o rechaza</strong> el reporte</div></div>
<div class="flow-step"><div class="flow-num">4</div><div class="flow-text">Si se valida, se ejecuta <strong>DBSCAN</strong> en segundo plano sobre incidentes confirmados</div></div>
<div class="flow-step"><div class="flow-num">5</div><div class="flow-text">Si se detecta nueva zona de riesgo, se dispara <strong>alerta push preventiva</strong> a ciudadanos cercanos</div></div>

---

# Inteligencia Artificial

<div class="cols">
<div class="card">
<h3>🗺 Motor espacial — DBSCAN</h3>
<ul>
<li>Entrada: incidentes confirmados georref.</li>
<li>Proceso: clustering por densidad espacial</li>
<li>Salida: zonas de riesgo con centroide y radio</li>
<li>Uso: alertas push y optimizacion de patrullaje</li>
</ul>
</div>
<div class="card">
<h3>📈 Motor temporal — Regresion Lineal</h3>
<ul>
<li>Entrada: historicos SIDPOL por distrito/mes</li>
<li>Modelo: regresion lineal supervisada</li>
<li>Salida: proyeccion trimestral de incidentes</li>
<li>Uso: planificacion operativa estrategica</li>
</ul>
</div>
</div>

<div class="highlight-box">
Las predicciones y zonas de riesgo se generan de forma asincrona y no bloquean la experiencia del usuario.
</div>

---

# Roles y Modulos

<div class="role-card ciudadano"><h3>👤 Ciudadano</h3><p>Reportar incidentes geolocalizados · ver zonas de riesgo en mapa · recibir alertas push · historial personal</p></div>
<div class="role-card policia"><h3>🚔 Policia</h3><p>Ver reportes pendientes en radio de 3 km · validar o rechazar · priorizar respuesta · registro de auditoria</p></div>
<div class="role-card admin"><h3>🖥 Administrador</h3><p>Dashboard de estadisticas y tendencias · consulta de predicciones por distrito · gestion de usuarios y reportes criticos</p></div>

---

# Stack Tecnologico

<div class="cols">
<div class="card">
<h3>Frontend</h3>
<div class="tag-row">
<span class="tech-pill">Flutter / Dart</span>
<span class="tech-pill">flutter_map</span>
<span class="tech-pill">fl_chart</span>
<span class="tech-pill">Geolocator</span>
<span class="tech-pill">Firebase SDK</span>
</div>
</div>
<div class="card">
<h3>Backend</h3>
<div class="tag-row">
<span class="tech-pill">Python 3.11+</span>
<span class="tech-pill">FastAPI</span>
<span class="tech-pill">Uvicorn</span>
<span class="tech-pill">Motor/PyMongo</span>
<span class="tech-pill">Pydantic</span>
</div>
</div>
</div>
<div class="cols" style="margin-top:16px">
<div class="card">
<h3>IA y Analitica</h3>
<div class="tag-row">
<span class="tech-pill">Scikit-learn</span>
<span class="tech-pill">Pandas</span>
<span class="tech-pill">NumPy</span>
<span class="tech-pill">DBSCAN</span>
<span class="tech-pill">ETL SIDPOL</span>
</div>
</div>
<div class="card">
<h3>Seguridad</h3>
<div class="tag-row">
<span class="tech-pill">JWT + RBAC</span>
<span class="tech-pill">Bcrypt</span>
<span class="tech-pill">HTTPS/TLS</span>
<span class="tech-pill">ASGI Async</span>
</div>
</div>
</div>

---

# Metricas Objetivo

<div class="metric-grid">
<div class="metric-card">
<div class="num">&lt; 2 min</div>
<div class="label">Validacion policial de reportes</div>
</div>
<div class="metric-card">
<div class="num">&lt; 300 ms</div>
<div class="label">Respuesta de endpoints criticos</div>
</div>
<div class="metric-card">
<div class="num">500 K</div>
<div class="label">Registros historicos SIDPOL ingestados</div>
</div>
</div>

<div class="highlight-box" style="margin-top:24px">
Metodologia SCRUM · 5 sprints incrementales · trazabilidad RF/RNF segun SRS y SAD
</div>

---

<!-- _class: lead -->

# Gracias

**SGEO** — De la reaccion a la prevencion

Piero Alexander Paja de la Cruz
2020067576@upt.pe · Universidad Privada de Tacna · 2026