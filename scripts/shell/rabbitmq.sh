echo "install erlang"

cat > /etc/yum.repos.d/rabbitmq_erlang.repo << 'EOF'
[rabbitmq_erlang]
name=rabbitmq_erlang
baseurl=https://packagecloud.io/rabbitmq/erlang/el/9/$basearch
gpgcheck=0
enabled=1
EOF
dnf install -y erlang


echo "install rabbitmq"
cat > /etc/yum.repos.d/rabbitmq_rabbitmq-server.repo << 'EOF'
[rabbitmq_rabbitmq-server]
name=rabbitmq_rabbitmq-server
baseurl=https://packagecloud.io/rabbitmq/rabbitmq-server/el/9/$basearch
gpgcheck=0
enabled=1
EOF
dnf install -y rabbitmq-server


echo "enabling and starting rabbitmq"
systemctl enable --now rabbitmq-server

echo "waiting for rabbitmq to be ready"
until rabbitmqctl ping &>/dev/null; do
  sleep 2
done

echo "setting up rabbitmq users and permissions"
rabbitmqctl add_user roboshop RoboShop@1 || true
rabbitmqctl set_user_tags roboshop administrator || true
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" || true

echo "restart rabbitmq service"
systemctl restart rabbitmq-server