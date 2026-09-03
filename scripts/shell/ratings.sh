echo "install dependencies"
dnf install -y python3 python3-pip mysql8.4

echo "download and unzip ratings code"
curl -L -o /tmp/ratings.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/ratings.zip
mkdir -p /app && cd /app
unzip /tmp/ratings.zip

echo "create db user and schema"
mysql -h <MYSQL-SERVER-IP> -u root -pRoboShop@1 < db/schema.sql
mysql -h <MYSQL-SERVER-IP> -u root -pRoboShop@1 < db/app-user.sql

echo "create app user"
useradd -r -s /bin/false appuser
mkdir -p /app

echo "install python dependencies"
pip3 install -r /app/requirements.txt cryptography

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "start ratings service"
systemctl daemon-reload
systemctl enable ratings
systemctl start ratings