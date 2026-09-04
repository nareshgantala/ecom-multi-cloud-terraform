#!/bin/bash

echo "Install nginx"
dnf install -y nginx unzip
systemctl enable nginx
systemctl start nginx

cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        location /api/catalogue/ {
            rewrite ^/api/catalogue/(.*)$ /$1 break;
            proxy_pass http://catalogue.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/user/ {
            rewrite ^/api/user/(.*)$ /$1 break;
            proxy_pass http://user.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/cart/ {
            rewrite ^/api/(.*)$ /$1 break;
            proxy_pass http://cart.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/shipping/ {
            rewrite ^/api/(.*)$ /$1 break;
            proxy_pass http://shipping.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/payment/ {
            rewrite ^/api/(.*)$ /$1 break;
            proxy_pass http://payment.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/ratings {
            rewrite ^/api/(.*)$ /$1 break;
            proxy_pass http://ratings.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/orders/ {
            rewrite ^/api/(.*)$ /$1 break;
            proxy_pass http://orders.naresh-training.online:80;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location / {
            try_files $uri $uri/index.html $uri.html /index.html;
        }

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 7d;
            add_header Cache-Control "public";
        }
    }
}
EOF

echo "Install Node JS"
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

echo "Download frontend Code"
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/frontend.zip
mkdir -p /tmp/frontend && cd /tmp/frontend
unzip -o /tmp/frontend.zip

echo "Install Node Dependencies"
npm install

echo "Build Frontend"
npm run build

echo "Deploy frontend"
rm -rf /usr/share/nginx/html/*
cp -r out/* /usr/share/nginx/html/


echo "Configure SELinux and Restart Nginx"
setsebool -P httpd_can_network_connect 1 || true
systemctl restart nginx
