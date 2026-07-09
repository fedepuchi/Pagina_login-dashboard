# import all libraries
import os
import calendar as calendar_module
from functools import wraps
from datetime import date
from flask import Flask, request, render_template, redirect, url_for, session
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
from dotenv import load_dotenv
from werkzeug.security import check_password_hash

app = Flask(__name__)
load_dotenv()
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.secret_key = os.getenv('SECRET_KEY', 'dev-secret-key-change-me')
db = SQLAlchemy(app)

DIAS_ES = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
MESES_ES = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
            'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre']


def formatear_fecha_es(fecha):
    return f"{DIAS_ES[fecha.weekday()]} {fecha.day} de {MESES_ES[fecha.month]} de {fecha.year}"


def construir_calendario(fecha):
   
    cal = calendar_module.Calendar(firstweekday=6)
    celdas = list(cal.itermonthdays3(fecha.year, fecha.month))
    return [celdas[i:i + 7] for i in range(0, len(celdas), 7)]


def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if 'usuario' not in session:
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return wrapper


@app.route('/')
def index():
    if 'usuario' in session:
        return redirect(url_for('dashboard'))
    return render_template('login.html')


@app.route('/form_login', methods=['POST'])
def login():
    name1 = request.form['username']
    pwd = request.form['password']

    query = text("SELECT contrasena FROM usuarios WHERE nombre = :usuario")
    result = db.session.execute(query, {"usuario": name1}).fetchone()

    if not result or not check_password_hash(result[0], pwd):
        return render_template('login.html', info='Usuario o contraseña incorrectos')

    session['usuario'] = name1
    return redirect(url_for('dashboard'))


@app.route('/dashboard')
@login_required
def dashboard():
    hoy = date.today()

    agenda_query = text("""
        SELECT a.nombre AS aseguradora, e.cliente, j.nombre AS juzgado
        FROM expedientes e
        JOIN aseguradoras a ON a.id = e.aseguradora_id
        JOIN juzgados j ON j.id = e.juzgado_id
        WHERE e.fecha_agenda = :hoy
        ORDER BY e.id
    """)
    agenda = db.session.execute(agenda_query, {"hoy": hoy}).fetchall()

    conteo_query = text("SELECT estado, COUNT(*) FROM expedientes GROUP BY estado")
    conteos = dict(db.session.execute(conteo_query).fetchall())

    return render_template(
        'dashboard.html',
        activo='inicio',
        fecha_larga=formatear_fecha_es(hoy),
        agenda=agenda,
        pendientes=conteos.get('pendiente', 0),
        en_curso=conteos.get('en_curso', 0),
        cerrados=conteos.get('cerrado', 0),
        mes_nombre=f"{MESES_ES[hoy.month].capitalize()} {hoy.year}",
        semanas=construir_calendario(hoy),
        hoy=hoy,
    )


@app.route('/expedientes')
@login_required
def expedientes():
    query = text("""
        SELECT e.id, a.nombre AS aseguradora, e.cliente, j.nombre AS juzgado,
               e.estado, e.fecha_agenda, u.nombre AS usuario
        FROM expedientes e
        JOIN aseguradoras a ON a.id = e.aseguradora_id
        JOIN juzgados j ON j.id = e.juzgado_id
        LEFT JOIN usuarios u ON u.id = e.usuario_id
        ORDER BY e.fecha_agenda DESC, e.id
    """)
    filas = db.session.execute(query).fetchall()
    return render_template('expedientes.html', activo='expedientes', filas=filas)


@app.route('/reportes')
@login_required
def reportes():
    query = text("""
        SELECT r.id, r.titulo, r.tipo, r.generado_en, u.nombre AS usuario
        FROM reportes r
        LEFT JOIN usuarios u ON u.id = r.usuario_id
        ORDER BY r.generado_en DESC
    """)
    filas = db.session.execute(query).fetchall()
    return render_template('reportes.html', activo='reportes', filas=filas)


@app.route('/aseguradoras')
@login_required
def aseguradoras():
    filas = db.session.execute(text("SELECT id, nombre FROM aseguradoras ORDER BY nombre")).fetchall()
    return render_template('catalogo.html', activo='aseguradoras', titulo='Aseguradoras', columna='Aseguradora', filas=filas)


@app.route('/usuarios')
@login_required
def usuarios():
    filas = db.session.execute(text("SELECT id, nombre FROM usuarios ORDER BY nombre")).fetchall()
    return render_template('catalogo.html', activo='usuarios', titulo='Usuarios', columna='Usuario', filas=filas)


@app.route('/juzgados')
@login_required
def juzgados():
    filas = db.session.execute(text("SELECT id, nombre FROM juzgados ORDER BY nombre")).fetchall()
    return render_template('catalogo.html', activo='juzgados', titulo='Juzgados', columna='Juzgado', filas=filas)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


if __name__ == '__main__':
    app.run(debug=True, port=int(os.getenv('PORT', 5000)))
