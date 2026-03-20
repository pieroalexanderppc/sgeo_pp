const { MongoClient } = require('mongodb');

const MONGODB_URI = 'mongodb://mongo:TU_PASSWORD@ballast.proxy.rlwy.net:12247/geocrimen_tacna';

async function setupDB() {
  const client = new MongoClient(MONGODB_URI);

  try {
    await client.connect();
    console.log('✅ Conectado a MongoDB Railway');

    const db = client.db('geocrimen_tacna');

    // ── 1. USUARIOS ────────────────────────────────────────────────────────
    await db.createCollection('usuarios', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['nombre', 'email', 'password_hash', 'rol'],
          properties: {
            nombre:        { bsonType: 'string' },
            email:         { bsonType: 'string' },
            password_hash: { bsonType: 'string' },
            rol:           { enum: ['ciudadano', 'policia', 'admin'] },
            telefono:      { bsonType: 'string' },
            ubicacion_default: {
              bsonType: 'object',
              properties: {
                type:        { enum: ['Point'] },
                coordinates: { bsonType: 'array' },
              },
            },
            distrito:  { bsonType: 'string' },
            ubigeo:    { bsonType: 'string' },
            activo:    { bsonType: 'bool' },
            creado_en: { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('usuarios').createIndexes([
      { key: { email: 1 },              name: 'email_unique',    unique: true },
      { key: { ubicacion_default: '2dsphere' }, name: 'ubicacion_2dsphere' },
      { key: { ubigeo: 1 },             name: 'ubigeo' },
      { key: { rol: 1 },                name: 'rol' },
    ]);
    console.log('✅ Colección usuarios creada');

    // ── 2. REPORTES_CIUDADANO ──────────────────────────────────────────────
    await db.createCollection('reportes_ciudadano', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['sub_tipo', 'modalidad', 'ubicacion', 'distrito', 'fecha_hecho', 'estado'],
          properties: {
            usuario_id: { bsonType: ['objectId', 'null'] },
            anonimo:    { bsonType: 'bool' },
            tipo:       { enum: ['PATRIMONIO (DELITO)'] },
            sub_tipo:   { enum: ['HURTO', 'ROBO', 'EXTORSION'] },
            modalidad:  { bsonType: 'string' },
            ubicacion: {
              bsonType: 'object',
              required: ['type', 'coordinates'],
              properties: {
                type:        { enum: ['Point'] },
                coordinates: { bsonType: 'array' },
              },
            },
            direccion:    { bsonType: 'string' },
            distrito:     { bsonType: 'string' },
            ubigeo:       { bsonType: 'string' },
            fecha_hecho:  { bsonType: 'date' },
            hora_aprox:   { bsonType: 'string' },
            descripcion:  { bsonType: 'string' },
            fotos:        { bsonType: 'array' },
            estado:       { enum: ['pendiente', 'confirmado', 'rechazado'] },
            revisado_por: { bsonType: ['objectId', 'null'] },
            nota_revision:{ bsonType: 'string' },
            incidente_id: { bsonType: ['objectId', 'null'] },
            creado_en:    { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('reportes_ciudadano').createIndexes([
      { key: { estado: 1 },      name: 'estado' },
      { key: { ubigeo: 1 },      name: 'ubigeo' },
      { key: { creado_en: -1 },  name: 'creado_en_desc' },
    ]);
    console.log('✅ Colección reportes_ciudadano creada');

    // ── 3. INCIDENTES ──────────────────────────────────────────────────────
    await db.createCollection('incidentes', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['fuente', 'sub_tipo', 'modalidad', 'ubicacion', 'distrito', 'fecha_hecho', 'anio', 'mes'],
          properties: {
            fuente:       { enum: ['ciudadano', 'policia', 'sidpol'] },
            reporte_id:   { bsonType: ['objectId', 'null'] },
            verificado_por: { bsonType: ['objectId', 'null'] },
            tipo:         { enum: ['PATRIMONIO (DELITO)'] },
            sub_tipo:     { enum: ['HURTO', 'ROBO', 'EXTORSION'] },
            modalidad:    { bsonType: 'string' },
            ubicacion: {
              bsonType: 'object',
              required: ['type', 'coordinates'],
              properties: {
                type:        { enum: ['Point'] },
                coordinates: { bsonType: 'array' },
              },
            },
            direccion:   { bsonType: 'string' },
            distrito:    { bsonType: 'string' },
            ubigeo:      { bsonType: 'string' },
            fecha_hecho: { bsonType: 'date' },
            anio:        { bsonType: 'int' },
            mes:         { bsonType: 'int', minimum: 1, maximum: 12 },
            descripcion: { bsonType: 'string' },
            fotos:       { bsonType: 'array' },
            creado_en:   { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('incidentes').createIndexes([
      { key: { ubicacion: '2dsphere' },        name: 'ubicacion_2dsphere' },
      { key: { ubigeo: 1, anio: 1, mes: 1 },   name: 'ubigeo_anio_mes' },
      { key: { sub_tipo: 1 },                  name: 'sub_tipo' },
      { key: { fuente: 1 },                    name: 'fuente' },
      { key: { fecha_hecho: -1 },              name: 'fecha_hecho_desc' },
    ]);
    console.log('✅ Colección incidentes creada');

    // ── 4. ESTADISTICAS_SIDPOL ─────────────────────────────────────────────
    await db.createCollection('estadisticas_sidpol', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['anio', 'mes', 'ubigeo', 'distrito', 'cantidad'],
          properties: {
            anio:         { bsonType: 'int' },
            mes:          { bsonType: 'int', minimum: 1, maximum: 12 },
            ubigeo:       { bsonType: 'string' },
            departamento: { bsonType: 'string' },
            provincia:    { bsonType: 'string' },
            distrito:     { bsonType: 'string' },
            tipo:         { bsonType: 'string' },
            sub_tipo:     { bsonType: 'string' },
            modalidad:    { bsonType: 'string' },
            cantidad:     { bsonType: 'int' },
            importado_en: { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('estadisticas_sidpol').createIndexes([
      {
        key: { ubigeo: 1, anio: 1, mes: 1, sub_tipo: 1, modalidad: 1 },
        name: 'unique_sidpol',
        unique: true,
      },
      { key: { ubigeo: 1 }, name: 'ubigeo' },
    ]);
    console.log('✅ Colección estadisticas_sidpol creada');

    // ── 5. ZONAS_RIESGO ────────────────────────────────────────────────────
    await db.createCollection('zonas_riesgo', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['centroide', 'radio_metros', 'distrito', 'nivel_riesgo', 'total_incidentes', 'tendencia'],
          properties: {
            centroide: {
              bsonType: 'object',
              required: ['type', 'coordinates'],
              properties: {
                type:        { enum: ['Point'] },
                coordinates: { bsonType: 'array' },
              },
            },
            radio_metros:         { bsonType: 'int' },
            distrito:             { bsonType: 'string' },
            ubigeo:               { bsonType: 'string' },
            nivel_riesgo:         { enum: ['bajo', 'medio', 'alto', 'critico'] },
            total_incidentes:     { bsonType: 'int' },
            delito_predominante:  { bsonType: 'string' },
            tendencia:            { enum: ['subiendo', 'estable', 'bajando'] },
            periodo_analizado: {
              bsonType: 'object',
              properties: {
                desde: { bsonType: 'date' },
                hasta: { bsonType: 'date' },
              },
            },
            calculado_en: { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('zonas_riesgo').createIndexes([
      { key: { centroide: '2dsphere' }, name: 'centroide_2dsphere' },
      { key: { nivel_riesgo: 1 },       name: 'nivel_riesgo' },
      { key: { ubigeo: 1 },             name: 'ubigeo' },
    ]);
    console.log('✅ Colección zonas_riesgo creada');

    // ── 6. ALERTAS ─────────────────────────────────────────────────────────
    await db.createCollection('alertas', {
      validator: {
        $jsonSchema: {
          bsonType: 'object',
          required: ['usuario_id', 'tipo', 'mensaje'],
          properties: {
            usuario_id:  { bsonType: 'objectId' },
            incidente_id:{ bsonType: ['objectId', 'null'] },
            zona_id:     { bsonType: ['objectId', 'null'] },
            tipo:        { enum: ['nuevo_incidente', 'zona_peligrosa', 'zona_actualizada'] },
            mensaje:     { bsonType: 'string' },
            leida:       { bsonType: 'bool' },
            push_enviado:{ bsonType: 'bool' },
            creado_en:   { bsonType: 'date' },
          },
        },
      },
    });
    await db.collection('alertas').createIndexes([
      { key: { usuario_id: 1, leida: 1 }, name: 'usuario_leida' },
      { key: { creado_en: -1 },           name: 'creado_en_desc' },
    ]);
    console.log('✅ Colección alertas creada');

    // ── RESUMEN ────────────────────────────────────────────────────────────
    const colecciones = await db.listCollections().toArray();
    console.log(`\n🎉 Base de datos lista. Colecciones creadas: ${colecciones.length}`);
    colecciones.forEach(c => console.log(`   • ${c.name}`));

  } catch (err) {
    if (err.codeName === 'NamespaceExists') {
      console.log(`⚠️  La colección ya existe, omitiendo: ${err.message}`);
    } else {
      console.error('❌ Error:', err.message);
    }
  } finally {
    await client.close();
    console.log('\n🔌 Desconectado.');
  }
}

setupDB();
