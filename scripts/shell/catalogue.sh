echo "copy catalogue service file"
cp catalogue.service /etc/systemd/system/catalogue.service

echo "install golang"
dnf install -y golang git mysql8.4

echo "version"
go version


echo "Download catalogue Code"
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/catalogue.zip
mkdir -p /app
cd /app
unzip /tmp/catalogue.zip

echo "download and load schema"
mysql -h <MYSQL-SERVER-IP> -u root -pRoboShop@1 < db/schema.sql

echo "download and load users"
mysql -h <MYSQL-SERVER-IP> -u root -pRoboShop@1 < db/app-user.sql

echo "download and load master data"
mysql -h <MYSQL-SERVER-IP> -u root -pRoboShop@1 catalogue < db/master-data.sql


echo "create catalogue user"
useradd -r -s /bin/false appuser

echo "download dependencies"
cd /app
go mod tidy

echo "build catalogue"
CGO_ENABLED=0 go build -o /app/catalogue .

echo "change ownership"
chown -R appuser:appuser /app
chmod o-rwx /app -R

echo "start service"
systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue