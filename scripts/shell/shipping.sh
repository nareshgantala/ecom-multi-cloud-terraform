echo "copy shipping service file"
cat > /etc/systemd/system/shipping.service << 'EOF'
[Unit]
Description=RoboShop Shipping Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=java -jar /app/shipping.jar
Restart=on-failure
RestartSec=10
SyslogIdentifier=shipping

Environment=DB_HOST=mysql.naresh-training.online
Environment=DB_USER=shipping
Environment=DB_PASS=RoboShop@1
Environment=PORT=8004

[Install]
WantedBy=multi-user.target
EOF

echo "install java, maven, mysql"
dnf install -y unzip java-21-openjdk java-21-openjdk-devel maven mysql8.4
java -version

echo "download and unzip shipping code"
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/shipping.zip
mkdir -p /app
cd /app
unzip /tmp/shipping.zip

echo "configure mysql"
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/schema.sql
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/app-user.sql

echo "create app user"
useradd -r -s /bin/false appuser

echo "build and package shipping code"
cd /app
mvn clean package -DskipTests
cp target/shipping.jar /app/shipping.jar

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "enable and start shipping service"
systemctl daemon-reload
systemctl enable shipping
systemctl start shipping