CREATE DATABASE login_db;


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
    estado         VARCHAR(20)  NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_curso', 'cerrado')),
    fecha_agenda   DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_id     INTEGER      REFERENCES usuarios(id) ON DELETE SET NULL,
    creado_en      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expedientes_fecha      ON expedientes (fecha_agenda);
CREATE INDEX IF NOT EXISTS idx_expedientes_estado      ON expedientes (estado);
CREATE INDEX IF NOT EXISTS idx_expedientes_aseguradora ON expedientes (aseguradora_id);
CREATE INDEX IF NOT EXISTS idx_expedientes_juzgado     ON expedientes (juzgado_id);

CREATE TABLE IF NOT EXISTS reportes (
    id          SERIAL PRIMARY KEY,
    titulo      VARCHAR(150) NOT NULL,
    tipo        VARCHAR(50)  NOT NULL,
    generado_en TIMESTAMP    NOT NULL DEFAULT NOW(),
    usuario_id  INTEGER      REFERENCES usuarios(id) ON DELETE SET NULL
);