FROM alpine:3

# Install mariadb
RUN apk add --no-cache mariadb mariadb-client

# Set up mariadb directory
RUN mkdir -p /run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

# Copy mariadb configuration
COPY my.cnf /etc/my.cnf

# Create and configure initialization directory
RUN mkdir -p /docker-entrypoint-initdb.d && \
    chown -R mysql:mysql /docker-entrypoint-initdb.d

EXPOSE 3306

CMD ["mysqld", "--user=mysql", "--init-file=/docker-entrypoint-initdb.d/init.sql"]