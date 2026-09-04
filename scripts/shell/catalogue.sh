echo "copy catalogue service file"
cat > /etc/systemd/system/catalogue.service << 'EOF'
[Unit]
Description=RoboShop Catalogue Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/app
ExecStart=/app/catalogue
Restart=on-failure
RestartSec=10
SyslogIdentifier=catalogue

Environment=MYSQL_HOST=mysql.naresh-training.online
Environment=MYSQL_USER=catalogue
Environment=MYSQL_PASSWORD=RoboShop@1
Environment=MYSQL_DATABASE=catalogue
Environment=PORT=8002

[Install]
WantedBy=multi-user.target
EOF

echo "install golang"
dnf install -y golang git mysql8.4 unzip

echo "version"
go version


echo "Download catalogue Code"
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/catalogue.zip
mkdir -p /app
cd /app
unzip -o /tmp/catalogue.zip

echo "wait for mysql to be ready"
until mysql -h mysql.naresh-training.online -u root -pRoboShop@1 -e "status" &>/dev/null; do
  echo "Waiting for MySQL at mysql.naresh-training.online:3306..."
  sleep 5
done

echo "download and load schema"
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/schema.sql

echo "download and load users"
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 < db/app-user.sql

echo "download and load master data"
mysql -h mysql.naresh-training.online -u root -pRoboShop@1 catalogue < db/master-data.sql


echo "create catalogue user"
useradd -r -s /bin/false appuser || true

echo "download dependencies"
export HOME=/root
export GOPATH=/root/go
export GOMODCACHE=/root/go/pkg/mod
cd /app
go mod tidy

echo "build catalogue"
CGO_ENABLED=0 go build -o /app/catalogue .

echo "change ownership"
chown -R appuser:appuser /app
chmod o-rwx /app -R
chcon -t bin_t /app/catalogue || true

echo "start service"
systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue