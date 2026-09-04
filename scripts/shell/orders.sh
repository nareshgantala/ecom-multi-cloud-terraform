echo "copy orders service file"
cat > /etc/systemd/system/orders.service << 'EOF'
[Unit]
Description=RoboShop Orders Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=java -jar /app/orders.jar
Restart=on-failure
RestartSec=10
SyslogIdentifier=orders

Environment=MONGO_URL=mongodb://mongodb.naresh-training.online:27017/orders
Environment=AMQP_HOST=rabbitmq.naresh-training.online
Environment=AMQP_USER=roboshop
Environment=AMQP_PASS=RoboShop@1
Environment=SHIPPING_URL=http://shipping.naresh-training.online
Environment=NOTIFICATION_URL=http://notification.naresh-training.online
Environment=PORT=8007

[Install]
WantedBy=multi-user.target
EOF

echo "install java and maven"
dnf install -y unzip java-21-openjdk java-21-openjdk-devel maven

echo "create app user"
useradd -r -s /bin/false appuser || true
mkdir -p /app

echo "download orders code"
curl -L -o /tmp/orders.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/orders.zip
mkdir -p /app && cd /app
unzip -o /tmp/orders.zip

echo "build orders code"
mvn clean package -DskipTests

echo "copy orders jar file"
cp target/orders.jar /app/orders.jar

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "start orders service"
systemctl daemon-reload
systemctl enable orders
systemctl start orders

