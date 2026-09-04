echo "copy user service file"
cat > /etc/systemd/system/user.service << 'EOF'
[Unit]
Description=RoboShop User Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
SyslogIdentifier=user

Environment=MONGO_URL=mongodb://mongodb.naresh-training.online:27017/users
Environment=JWT_SECRET=roboshop-secret-key
Environment=PORT=8001

[Install]
WantedBy=multi-user.target
EOF


echo "install nodejs"
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs unzip

echo "version"
node --version
npm --version

echo "create user appuser"
useradd -r -s /bin/false appuser
mkdir -p /app

echo "download and unzip user code"
curl -L -o /tmp/user.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/user.zip
cd /app
unzip /tmp/user.zip

echo "install dependencies"
npm install --production


echo "change ownership"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "start service"
systemctl daemon-reload
systemctl enable user
systemctl start user