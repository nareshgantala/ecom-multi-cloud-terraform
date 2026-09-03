echo "copy user service file"
cp user.service /etc/systemd/system/user.service


echo "install nodejs"
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

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