echo "copy mongo repo file"
cp mongo.repo /etc/yum.repos.d/mongodb-org-7.0.repo

echo "install mongodb"
dnf install -y mongodb-org

echo "enable and start mongodb"
systemctl enable mongod
systemctl start mongod

echo "change mongodb config to allow remote connections"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf


echo "restart mongodb"
systemctl restart mongod
