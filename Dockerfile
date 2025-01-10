FROM alpine:3

# Install MariaDB and curl for downloading files
RUN apk add --no-cache mariadb mariadb-client curl

# Set up MariaDB directories and permissions
RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Create the initialization directory (fix: ensure this directory exists before downloading files)
RUN mkdir -p /docker-entrypoint-initdb.d

# Fetch MariaDB configuration and scripts from URLs
RUN curl -o /docker-entrypoint.sh https://raw.githubusercontent.com/jonoo0/mariadb-alpine/refs/heads/main/docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh && \
    curl -o /docker-entrypoint-initdb.d/init.sql https://raw.githubusercontent.com/jonoo0/mariadb-alpine/refs/heads/main/init.sql && \
    curl -o /etc/my.cnf https://raw.githubusercontent.com/jonoo0/mariadb-alpine/refs/heads/main/my.cnf

# Expose the default MariaDB port
EXPOSE 3306

# Start MariaDB with the init script
CMD ["mysqld", "--user=mysql", "--init-file=/docker-entrypoint-initdb.d/init.sql"]
