#!/bin/bash
set -e

echo "Installing MariaDB/MySQL Server"
dnf install -y mariadb-server mariadb

echo "Configuring MySQL to listen on all interfaces"
if [ -f /etc/my.cnf.d/mariadb-server.cnf ]; then
  if grep -q "bind-address" /etc/my.cnf.d/mariadb-server.cnf; then
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
  else
    sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' /etc/my.cnf.d/mariadb-server.cnf
  fi
fi

echo "Enabling and starting mariadb"
systemctl enable --now mariadb

echo "Waiting for MySQL service to be ready"
until mysqladmin ping -u root --silent; do
  echo "Waiting for database to accept connections..."
  sleep 2
done

echo "Configuring root password and remote access"
mysql -u root <<EOF
GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'RoboShop@1' WITH GRANT OPTION;
GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY 'RoboShop@1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "MySQL installation and initialization complete"

