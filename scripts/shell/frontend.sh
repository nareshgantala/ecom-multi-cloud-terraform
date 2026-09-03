#!/bin/bash

echo "Install nginx"
dnf install -y nginx
systemctl enable nginx
systemctl start nginx


echo "Install Node JS"
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

echo "Download frontend Code"
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts/frontend.zip
mkdir -p /tmp/frontend && cd /tmp/frontend
unzip /tmp/frontend.zip

echo "Install Node Dependencies"
npm install

echo "Build Frontend"
npm run build

echo "Deploy frontend"
rm -rf /usr/share/nginx/html/*
cp -r out/* /usr/share/nginx/html/
