echo "copy mongo repo file"
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << 'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=0
enabled=1
EOF

echo "install mongodb"
dnf install -y mongodb-org

echo "enable and start mongodb"
systemctl enable mongod
systemctl start mongod

echo "change mongodb config to allow remote connections"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf


echo "restart mongodb"
systemctl restart mongod
