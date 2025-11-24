FROM postgres:15-alpine

# Copy initialization script into the image
COPY init.sql /docker-entrypoint-initdb.d/init.sql

# Set proper permissions
RUN chmod 644 /docker-entrypoint-initdb.d/init.sql

# Postgres automatically runs all .sql files in /docker-entrypoint-initdb.d/
# on first startup when the data directory is empty
# This ensures consistent initialization across all environments
