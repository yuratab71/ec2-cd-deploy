#!/bin/bash

set -e

# Just example bootstrap script

sudo apt-get update -y
sudo apt-get install docker.io -y
sudo apt-get install docker-compose-v2
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

git clone https://github.com/ghostfolio/ghostfolio ./app

cd ./app

touch .env

cat <<EOF >.env
COMPOSE_PROJECT_NAME=yuratab_ghostfolio

# CACHE
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=admin

# POSTGRES
POSTGRES_DB=ghostfolio-db
POSTGRES_USER=user
POSTGRES_PASSWORD=admin

# VARIOUS
ACCESS_TOKEN_SALT=12345678
DATABASE_URL=postgresql://user:admin@postgres:5432/ghostfolio-db?connect_timeout=300
JWT_SECRET_KEY=aRDTM3j5x1gauV4z1PAqsfX5+C7L5ZDWYUkMzwwtOho=
EOF

cd ./docker

docker compose up -d

mkdir -p /etc/nginx
touch /etc/nginx/nginx.conf

cat <<EOF >/etc/nginx/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /run/nginx.pid;


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

#After that, certbot needs to be configured via ssh
