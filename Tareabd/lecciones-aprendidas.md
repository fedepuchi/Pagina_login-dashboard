# Lecciones aprendidas — Login y Agenda del día

## Resumen del alcance

Dos pantallas sobre Flask + PostgreSQL (contenedor Docker):

- **Login**: ya existía; se completó el flujo para que use `session` de Flask y
  redirija a la agenda en vez de devolver un JSON suelto.
- **Agenda del día**: pantalla nueva (`/dashboard`), con datos reales desde una
  tabla `expedientes` agregada al esquema.

## Hallazgos técnicos durante la implementación

- **Faltaba el enrutamiento entre pantallas.** El login validaba credenciales
  pero terminaba en un `jsonify`, sin llevar a ningún lado. Se agregó
  `session['usuario']` + `redirect(url_for('dashboard'))`, y se protegió
  `/dashboard` para que redirija a `/` si no hay sesión activa.

- **La contraseña de prueba estaba en texto plano.** La tabla `usuarios` tenía
  `contrasena = 'fede1234'` sin hashear, pero el código ya usaba
  `check_password_hash`, que espera un hash. Se regeneró el hash con
  `generate_password_hash` y se actualizó el registro. Esto es un recordatorio
  de que la validación del login no se puede probar de verdad sin datos
  consistentes con lo que espera el código.

- **`scrypt` no funcionó en este entorno.** El método por defecto de
  `generate_password_hash` en Werkzeug moderno es `scrypt`, que requiere
  soporte de OpenSSL en el `hashlib` de Python. El Python del sistema
  (Command Line Tools, enlazado contra LibreSSL) no lo trae, y falla con
  `AttributeError: module 'hashlib' has no attribute 'scrypt'`. Se resolvió
  generando los hashes con `method='pbkdf2:sha256'`, que no depende de esa
  extensión. `check_password_hash` no necesitó cambios: detecta el método
  automáticamente a partir del prefijo del hash guardado.

- **El entorno virtual no tenía las dependencias instaladas.** `backend/venv`
  solo traía `pip`/`setuptools`; Flask, SQLAlchemy, `python-dotenv`,
  `psycopg2-binary` y Werkzeug no estaban instalados, así que el proyecto no
  podía correr tal como estaba. Se instalaron y se generó `requirements.txt`
  para dejar el entorno reproducible.

- **`bd.py` estaba vacío** y toda la lógica de conexión terminó viviendo en
  `app.py` vía `flask_sqlalchemy`. Se dejó así para no reestructurar código
  fuera del alcance de la tarea, pero es candidato a separar en un módulo de
  acceso a datos si el proyecto crece a más pantallas.

- **El puerto 5000 está ocupado por el sistema.** En macOS, el servicio
  "AirPlay Receiver" (`ControlCenter`) escucha por defecto en el puerto 5000,
  lo cual puede confundir al verificar si el servidor Flask realmente
  arrancó. Se agregó soporte a `PORT` por variable de entorno
  (`app.run(port=int(os.getenv('PORT', 5000)))`) para poder correr en otro
  puerto sin tocar el código cada vez.

## Reflexión (completar)

> Espacio para que completes con tus propias palabras: qué se te hizo más
> difícil, qué harías distinto la próxima vez, qué te llevas para el resto
> del curso/proyecto.

- ¿Qué fue lo más difícil de esta tarea?
- ¿Qué conceptos de bases de datos reforzaste (esquemas, claves foráneas,
  índices, hashing de contraseñas)?
- ¿Qué cambiarías del diseño si tuvieras que agregar las 7 pantallas
  restantes del flujo completo?
