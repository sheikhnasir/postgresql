/*
  MODULE 1 — CREATE THE LAB DATABASE
  Run this file while connected to the default postgres database.
  CREATE DATABASE must not be run inside BEGIN/COMMIT.
*/

CREATE DATABASE techstore_db
    WITH ENCODING = 'UTF8'
         TEMPLATE = template0;

-- In pgAdmin: open a new Query Tool connected to techstore_db.
-- In psql: \connect techstore_db

-- DESTRUCTIVE RESET (trainer only; keep commented unless confirmed):
-- SELECT pg_terminate_backend(pid)
-- FROM pg_stat_activity
-- WHERE datname = 'techstore_db' AND pid <> pg_backend_pid();
-- DROP DATABASE techstore_db;

