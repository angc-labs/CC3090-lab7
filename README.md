# Laboratorio 07 - Metabase

[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Metabase](https://img.shields.io/badge/Metabase-v0.49.0-509EE3?logo=metabase&logoColor=white)](https://www.metabase.com/)

## Requisitos

1. Docker y Docker Compose instalados.
2. Un archivo `.env` creado a partir de `.env.example`.

## Ejecución

1. Copiar el archivo de entorno y el archivo docker-compose:

```bash
cp .env.example .env
cp docker-compose.yml.example docker-compose.yml
```

2. Levantar los servicios:

```bash 
docker compose up --build -d
```

3. Verificar el estado:

```bash
docker compose logs -f
```

4. Abrir Metabase en `http://localhost:3000`.

El servicio `metabase-init` se ejecuta automáticamente durante `docker compose up` cuando Postgres y Metabase ya están listos.

<img width="800" height="500" alt="running" src="https://github.com/user-attachments/assets/6b082338-b743-4872-b2ab-9505ed8c6853" />

https://github.com/user-attachments/assets/dbfa8223-f02e-4b2d-b88a-3f8be0a1b046

## Docker Compose

- Levanta `postgres` y `metabase`.
- Carga automáticamente `sql/DDL.sql` y `sql/DATA.sql` en PostgreSQL al inicializar el contenedor.
- Persiste la base interna de Metabase en `metabase-data/`.
- Crea el usuario administrador inicial de Metabase y registra automáticamente la base PostgreSQL en Metabase durante `docker compose up`.

## Credenciales por defecto de Metabase

Al iniciarse por primera vez el contenedor, el servicio intentará crear un usuario administrador con las siguientes credenciales (puedes cambiarlas en `.env`):

- Correo: `calificar@uvg.edu.gt`
- Contraseña: `secret123+`

## Video

https://drive.google.com/file/d/1-0BOXVYq37YEKxnFQXNY309O0up_gJWA/view?usp=sharing 
