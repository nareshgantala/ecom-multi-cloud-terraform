echo "copy orders service file"
cp orders.service /etc/systemd/system/orders.service

echo "install java and maven"
dnf install -y java-21-openjdk java-21-openjdk-devel maven

echo "create app user"
useradd -r -s /bin/false appuser
mkdir -p /app

echo "download orders code"
curl -L -o /tmp/orders.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/orders.zip
mkdir -p /app && cd /app
unzip /tmp/orders.zip

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

