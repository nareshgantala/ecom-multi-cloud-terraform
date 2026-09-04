echo "copy payment service file"
cat > /etc/systemd/system/payment.service << 'EOF'
[Unit]
Description=RoboShop Payment Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8005
Restart=on-failure
RestartSec=10
SyslogIdentifier=payment

Environment=AMQP_HOST=rabbitmq.naresh-training.online
Environment=AMQP_USER=roboshop
Environment=AMQP_PASS=RoboShop@1
Environment=CART_URL=http://cart.naresh-training.online
Environment=USER_URL=http://user.naresh-training.online
Environment=PORT=8005

[Install]
WantedBy=multi-user.target
EOF

echo "install python and pip"
dnf install -y python3 python3-pip unzip
python3 --version

echo "create app user"
useradd -r -s /bin/false appuser || true
mkdir -p /app

echo "download payment code"
curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/payment.zip
cd /app
unzip -o /tmp/payment.zip

echo "install python dependencies"
pip3 install -r requirements.txt

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "start payment service"
systemctl daemon-reload
systemctl enable payment
systemctl start payment

