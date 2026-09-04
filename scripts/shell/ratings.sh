
cat > /etc/systemd/system/ratings.service << 'EOF'
[Unit]
Description=RoboShop Ratings Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=gunicorn -b 0.0.0.0:8006 app:app
Restart=on-failure
RestartSec=10
SyslogIdentifier=ratings

Environment=MYSQL_HOST=mysql.naresh-training.online
Environment=MYSQL_USER=ratings
Environment=MYSQL_PASSWORD=RoboShop@1
Environment=MYSQL_DATABASE=ratings
Environment=PORT=8006

[Install]
WantedBy=multi-user.target
EOF

echo "install dependencies"
dnf install -y python3 python3-pip mysql8.4

echo "download and unzip ratings code"
curl -L -o /tmp/ratings.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/ratings.zip
mkdir -p /app && cd /app
unzip /tmp/ratings.zip

echo "create db user and schema"
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/schema.sql
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/app-user.sql

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