#!/bin/bash

# EXAMPLE BOOTSTRAP SCRIPT, RUNS ON INSTANCE CREATION
#INSTALL ALL NECESSARY SOFTWARE TO EC2 INSTANCE

set -e

cd ~

# INSTALL DOCKER
sudo apt-get update -y
sudo apt-get install docker.io -y
sudo apt-get install docker-compose-v2
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

sudo mkdir -p /home/ubuntu/docker
sudo chown -R ubuntu:ubuntu /home/ubuntu/docker

# INSTALL AWS

sudo apt update && sudo apt install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805770710316.dkr.ecr.us-east-1.amazonaws.com

# INSTALL CERTBOT

sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/local/bin/certbot

# INSTALL AND SETUP NGINX

mkdir -p /etc/nginx
touch /etc/nginx/nginx.conf

cat <<EOF >/etc/nginx/nginx.conf
worker_processes  auto;

events {
	worker_connections  1024;
}

http {
	server {
		listen 80;
		listen [::]:80;

		server_name yuratab.pp.ua;

		location / {
			proxy_pass http://127.0.0.1:3333;
		}
	}
}
EOF

sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'

# INSTALL INOTIFY TOOLS

sudo apt install inotify-tools
