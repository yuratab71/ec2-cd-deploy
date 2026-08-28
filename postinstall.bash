#!/bin/bash

# EXAMPLE POSTINSTALL SCRIPT, JUST RUN AFTER CREATING THE INSTANCE

set -e

# RUN DOCKER

cd ~/docker
docker compose --env-file ../.env up -d

# CONFIGURE CERTBOT

sudo certbot --nginx

# RESTART NGINX

sudo service nginx restart
sudo nginx -s reload -t
