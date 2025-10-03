#!/bin/bash
apt update -y
apt install -y nginx awscli
echo "<h1>opentofu lab 01</h1><p>Instância rodando</p>" > /var/www/html/index.html
systemctl restart nginx
