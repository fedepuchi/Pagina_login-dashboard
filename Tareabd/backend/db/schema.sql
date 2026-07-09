
CREATE TABLE IF NOT EXISTS usuarios (
    id         SERIAL PRIMARY KEY,
    nombre     VARCHAR(50)  NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS aseguradoras (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS juzgados (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS expedientes (
    id             SERIAL PRIMARY KEY,
    aseguradora_id INTEGER      NOT NULL REFERENCES aseguradoras(id),
    cliente        VARCHAR(150) NOT NULL,
    juzgado_id     INTEGER      NOT NULL REFERENCES juzgados(id),
    estado         VARCHAR(20)  NOT NULL DEFAULT 'pendiente'
                   CHECK (estado IN ('pendiente', 'en_curso', 'cerrado')),
    fecha_agenda   DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_id     INTEGER      REFERENCES usuarios(id) ON DELETE SET NULL,
    creado_en      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expedientes_fecha        ON expedientes (fecha_agenda);
CREATE INDEX IF NOT EXISTS idx_expedientes_estado        ON expedientes (estado);
CREATE INDEX IF NOT EXISTS idx_expedientes_aseguradora   ON expedientes (aseguradora_id);
CREATE INDEX IF NOT EXISTS idx_expedientes_juzgado       ON expedientes (juzgado_id);

CREATE TABLE IF NOT EXISTS reportes (
    id          SERIAL PRIMARY KEY,
    titulo      VARCHAR(150) NOT NULL,
    tipo        VARCHAR(50)  NOT NULL,  
    generado_en TIMESTAMP    NOT NULL DEFAULT NOW(),
    usuario_id  INTEGER      REFERENCES usuarios(id) ON DELETE SET NULL
);



INSERT INTO aseguradoras (nombre) VALUES
    ('ASSA'), ('ANCON'), ('CONANCE'), ('PARTICULAR'), ('INTEROCEANICA')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO juzgados (nombre) VALUES
    ('JUZGADO 5TO (PEDREGAL)'), ('JUZGADO 4TO (PEDREGAL)'),
    ('JUZGADO 1RO (PEDREGAL)'), ('JUZGADO 3RO (PEDREGAL)'),
    ('ALCALDIA DE PANAMA'), ('CHITRE')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO expedientes (aseguradora_id, cliente, juzgado_id, estado, fecha_agenda)
SELECT a.id, datos.cliente, j.id, datos.estado, CURRENT_DATE
FROM (VALUES
    ('ASSA',          'ANTHONY TREJOS',      'JUZGADO 5TO (PEDREGAL)', 'pendiente'),
    ('ANCON',         'LUIS MOLINA',         'JUZGADO 4TO (PEDREGAL)', 'pendiente'),
    ('ASSA',          'KATHERINE KENT',      'JUZGADO 5TO (PEDREGAL)', 'en_curso'),
    ('CONANCE',       'MARTIN ALVARADO',     'JUZGADO 1RO (PEDREGAL)', 'pendiente'),
    ('PARTICULAR',    'JOEL ARAUZ RODRIGUEZ','JUZGADO 3RO (PEDREGAL)', 'en_curso'),
    ('INTEROCEANICA', 'MICHELLE VEGA',       'ALCALDIA DE PANAMA',     'pendiente'),
    ('ANCON',         'CANDICE HENRY',       'CHITRE',                 'cerrado')
) AS datos(aseguradora, cliente, juzgado, estado)
JOIN aseguradoras a ON a.nombre = datos.aseguradora
JOIN juzgados j     ON j.nombre = datos.juzgado
ON CONFLICT DO NOTHING;

INSERT INTO reportes (titulo, tipo, usuario_id)
SELECT 'Expedientes pendientes - julio 2026', 'expedientes_por_estado', (SELECT id FROM usuarios ORDER BY id LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM reportes)
UNION ALL
SELECT 'Expedientes por aseguradora - julio 2026', 'expedientes_por_aseguradora', (SELECT id FROM usuarios ORDER BY id LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM reportes);
