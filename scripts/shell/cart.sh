echo "copy cart service file"
cat > /etc/systemd/system/cart.service << 'EOF'
[Unit]
Description=RoboShop Cart Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=10
SyslogIdentifier=cart

Environment=REDIS_HOST=valkey.naresh-training.online
Environment=CATALOGUE_URL=http://catalogue.naresh-training.online:8002
Environment=PORT=8003

[Install]
WantedBy=multi-user.target
EOF

echo "install nodejs"
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

echo "create app user"
useradd -r -s /bin/false appuser
mkdir -p /app

echo "download and unzip cart code"
curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/cart.zip
cd /app
unzip /tmp/cart.zip

echo "install npm dependencies"
npm install --production

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R

echo "enable and start cart service"
systemctl daemon-reload
systemctl enable cart
systemctl start cart