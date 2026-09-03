echo "copy payment service file"
cp payment.service /etc/systemd/system/payment.service


echo "install python and pip"
dnf install -y python3 python3-pip
python3 --version

echo "create app user"
useradd -r -s /bin/false appuser
mkdir -p /app

echo "download payment code"
curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/payment.zip
cd /app
unzip /tmp/payment.zip

echo "install python dependencies"
pip3 install -r requirements.txt

echo "set ownership and permissions"
chown -R appuser:appuser /app
chmod o-rwx /app -R


echo "start payment service"
systemctl daemon-reload
systemctl enable payment
systemctl start payment

