/* =========================================================
   PART 1: Run as postgres
   ========================================================= */

CREATE USER viewer_user
WITH
    LOGIN
    PASSWORD 'Strong_Password_123!'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION;

GRANT CONNECT ON DATABASE salesdb
TO viewer_user;

ALTER ROLE viewer_user
SET default_transaction_read_only = ON;


/* =========================================================
   PART 2: Connect to salesdb before running this section
   ========================================================= */

GRANT USAGE ON SCHEMA sales
TO viewer_user;

GRANT SELECT ON ALL TABLES IN SCHEMA sales
TO viewer_user;

GRANT SELECT ON ALL SEQUENCES IN SCHEMA sales
TO viewer_user;

REVOKE CREATE ON SCHEMA sales
FROM viewer_user;


/* =========================================================
   PART 3: Permissions for future objects
   Replace app_owner with the role that creates tables
   ========================================================= */

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner
IN SCHEMA sales
GRANT SELECT ON TABLES TO viewer_user;

ALTER DEFAULT PRIVILEGES FOR ROLE app_owner
IN SCHEMA sales
GRANT SELECT ON SEQUENCES TO viewer_user;