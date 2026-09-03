echo "install valkey"
dnf install -y valkey

echo "enable and start valkey"
systemctl enable valkey
systemctl start valkey

echo "update config file"
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/valkey/valkey.conf
sed -i "s/protected-mode yes/protected-mode no/g" /etc/valkey/valkey.conf

echo "restart valkey"
systemctl restart valkey
