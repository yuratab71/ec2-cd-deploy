#!/bin/bash

# EXAMPLE BOOTSTRAP SCRIPT, RUNS ON INSTANCE CREATION
#INSTALL ALL NECESSARY SOFTWARE TO EC2 INSTANCE

echo "//============== USER_DATA START ======================"

export DEBIAN_FRONTEND=noninteractive

set -e
set -x

cd ~

log() {
  echo "$1" >>/home/ubuntu/user_data.log
}

# INSTALL DOCKER
#
log "Installing Docker..."

sudo apt-get update -y
sudo apt-get install docker.io -y
sudo apt-get install docker-compose-v2 -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

log "Docker installed successfully"

# INSTALL AWS

log "Installing AWS..."

sudo apt-get install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805770710316.dkr.ecr.us-east-1.amazonaws.com

log "AWS installed successfuly"

# INSTALL CERTBOT

log "Installing certbot..."

sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/local/bin/certbot

log "Installing certbot - SUCCESS"

# INSTALL AND SETUP NGINX

log "Installing NGINX..."

sudo apt-get install nginx -y

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

nginx -t

log "Installing NGINX - SUCCESS"

# INSTALL INOTIFY TOOLS

log "Installing inotify tools..."

sudo apt-get install inotify-tools -y

log "Installing inotify tools - SUCCESS"

echo "//============== USER_DATA END  ======================"
