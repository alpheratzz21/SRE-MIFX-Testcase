-- init.sql
-- this file is automatically executed when PostgreSQL container is started for the first time

-- Create user read-only with password
CREATE USER readonly_user WITH PASSWORD 'readpass';

-- User fullaccess_user automatically created from variable environment in docker compose
-- Move to sre database
\c sre

-- Give fullaccess_user all privileges on the sre database
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO fullaccess_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO fullaccess_user;

-- Give readonly_user read-only access
GRANT CONNECT ON DATABASE sre TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;