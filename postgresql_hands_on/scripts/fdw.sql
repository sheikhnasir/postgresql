CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER techstore_database_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '127.0.0.1',
    port '5432',
    dbname 'techstore_db'
);

DROP USER MAPPING;

DROP USER MAPPING FOR CURRENT_USER
SERVER techstore_database_server;


CREATE USER MAPPING FOR CURRENT_USER
SERVER techstore_database_server
OPTIONS (
    user 'postgres',
    password 'Pa$$w0rd'
);

CREATE SCHEMA remote_techstore;

IMPORT FOREIGN SCHEMA sales
FROM SERVER techstore_database_server
INTO remote_techstore;



SELECT
    foreign_table_schema,
    foreign_table_name
FROM information_schema.foreign_tables
WHERE foreign_table_schema = 'remote_techstore';



SELECT *
FROM remote_techstore.orders;