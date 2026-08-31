#!/bin/bash

# EXAMPLE POSTINSTALL SCRIPT, JUST RUN AFTER CREATING THE INSTANCE

set -e

sudo apt install inotify-tools

# RUN DOCKER

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 805770710316.dkr.ecr.us-east-1.amazonaws.com

cd ~/docker
docker compose --env-file ../.env up -d

# CONFIGURE CERTBOT

sudo certbot --nginx

WATCHER_PATH="/usr/local/bin/docker-watcher.sh"

sudo tee $WATCHER_PATH <<EOF
#!/bin/bash

WATCH_DIR="/home/ubuntu/docker"
LOG="/var/log/docker-watcher.log"
TARGET="docker-compose.yml"

echo "Watching \$WATCH_DIR..." >>"\$LOG"

inotifywait -m -r -e close_write \
  --format '%T %w %f %e' \
  --timefmt '%Y-%m-%dT%H:%M:%S' \
  "\$WATCH_DIR" | while read DATETIME DIRECTORY FILE EVENT; do

  if [ "\$FILE" = "\$TARGET" ]; then
    echo "\$DATETIME: Change detected - \$DIRECTORY$FILE (\$EVENT)" >>"\$LOG"
    cd \$WATCH_DIR
    docker compose pull
    docker compose --env-file ../.env up -d --build
  fi
done
EOF

sudo chmod +x $WATCHER_PATH

sudo tee /etc/systemd/system/docker-watcher.service <<EOF
[Unit]
Description=Watch docker compose file

[Service]
Type=simple
ExecStart=/usr/local/bin/docker-watcher.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now docker-watcher
