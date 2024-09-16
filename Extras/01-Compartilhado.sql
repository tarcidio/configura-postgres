CREATE ROLE compartilhado WITH PASSWORD 'scc244';

GRANT CONNECT ON DATABASE "alunos15" TO compartilhado; 
GRANT CONNECT ON DATABASE "alunos80" TO compartilhado; 
GRANT CONNECT ON DATABASE "fapcov2103" TO compartilhado; 

GRANT USAGE ON SCHEMA "public" TO compartilhado;
GRANT SELECT ON ALL TABLES IN SCHEMA "public" TO compartilhado;

ALTER ROLE compartilhado LOGIN;