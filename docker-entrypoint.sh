#!/bin/sh
set -e

# Check if the database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # Initialize MariaDB data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Start MariaDB server temporarily
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    pid="$!"

    # Wait for MariaDB to start
    for i in {30..0}; do
        if mysql --protocol=socket -uroot -hlocalhost --socket=/run/mysqld/mysqld.sock -e "SELECT 1" &> /dev/null; then
            break
        fi
        sleep 1
    done

    # Set root password and create initial database and user
    if [ "$MYSQL_ROOT_PASSWORD" != "" ]; then
        mysql --protocol=socket -uroot -hlocalhost --socket=/run/mysqld/mysqld.sock << EOF
            SET @@SESSION.SQL_LOG_BIN=0;
            DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost');
            SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');
            CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
            GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
            FLUSH PRIVILEGES;
EOF

        if [ "$MYSQL_DATABASE" != "" ]; then
            mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" -hlocalhost --socket=/run/mysqld/mysqld.sock << EOF
                CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;
EOF

            if [ "$MYSQL_USER" != "" ] && [ "$MYSQL_PASSWORD" != "" ]; then
                mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" -hlocalhost --socket=/run/mysqld/mysqld.sock << EOF
                    CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
                    GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '${MYSQL_USER}'@'%';
                    FLUSH PRIVILEGES;
EOF
            fi
        fi
    fi

    # Stop temporary MariaDB server
    kill -s TERM "$pid"
    wait "$pid"
fi

# Execute the main command (usually mysqld)
exec "$@"