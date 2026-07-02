# Tarea BD — Login y Agenda del día

Aplicación Flask con dos pantallas:

1. **Login** (`/`) — autentica contra la tabla `usuarios` de PostgreSQL.
2. **Agenda del día** (`/dashboard`) — lista los expedientes del día, contadores de
   pendientes/en curso/cerrados y un calendario, usando la tabla `expedientes`.

## Requisitos

- Python 3.9+
- Docker (para la base de datos PostgreSQL)

## 1. Levantar la base de datos

```bash
docker run --name auth-postgres \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=login_db \
  -p 5432:5432 \
  -d postgres
```

Si el contenedor ya existe, solo arráncalo:

```bash
docker start auth-postgres
```

Aplica el esquema (tablas `usuarios` y `expedientes`, con datos de ejemplo):

```bash
docker cp backend/db/schema.sql auth-postgres:/schema.sql
docker exec auth-postgres psql -U myuser -d login_db -f /schema.sql
```

## 2. Configurar variables de entorno

Copia `.env.example` a `.env` en la raíz del proyecto y ajusta los valores si hace falta:

```bash
cp .env.example .env
```

## 3. Instalar dependencias y correr el servidor

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

La app queda disponible en `http://127.0.0.1:5000`.

## 4. Crear un usuario de prueba

Las contraseñas se guardan con hash (`werkzeug.security.generate_password_hash`),
nunca en texto plano:

```bash
python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('tu-clave', method='pbkdf2:sha256'))"
```

Inserta el resultado en la base:

```sql
INSERT INTO usuarios (nombre, contrasena) VALUES ('tu-usuario', '<hash-generado>');
```

> Nota: en este entorno de desarrollo el Python del sistema no soporta el método
> `scrypt` (por defecto en Werkzeug) debido a limitaciones de OpenSSL/LibreSSL.
> Por eso se genera el hash con `method='pbkdf2:sha256'`. Ver
> [lecciones-aprendidas.md](lecciones-aprendidas.md).

## Rutas

| Ruta          | Método | Descripción                                   |
|---------------|--------|------------------------------------------------|
| `/`           | GET    | Muestra el login (o redirige a `/dashboard` si ya hay sesión) |
| `/form_login` | POST   | Valida credenciales y crea la sesión           |
| `/dashboard`  | GET    | Pantalla "Agenda del día" (requiere sesión)    |
| `/logout`     | GET    | Cierra la sesión                               |

## Estructura

```
backend/
  app.py                  # rutas y lógica
  db/schema.sql            # esquema de la base de datos + datos de ejemplo
  static/style.css         # estilos del login
  static/dashboard.css     # estilos de la agenda
  templates/login.html
  templates/dashboard.html
  requirements.txt
```
