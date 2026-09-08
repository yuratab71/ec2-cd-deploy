#!/bin/bash

POSTGRES_DB="ghostfolio-db"
POSTGRES_USER="user"
# POSTGRES_PASSWORD="admin"

DUMPS_PATH="/home/ubuntu/dumps"
DATE="$(date +'%Y-%m-%d_%H:%M:%S')"
FILENAME="$DATE-backup.sql"
CONTAINER_ID="$(docker ps -aqf "name=postgres")"

docker exec -i "$CONTAINER_ID" pg_dump -U $POSTGRES_USER $POSTGRES_DB >"$DUMPS_PATH/$FILENAME"

if [ $? -ne 0 ]; then
  echo "$DATE: failed to dump the file from $CONTAINER_ID" >>"$DUMPS_PATH/log.txt"
  exit
fi

echo "$DATE: Successfully dumped file from $CONTAINER_ID" >>"$DUMPS_PATH/log.txt"

aws s3 cp "$DUMPS_PATH/$FILENAME" s3://ghostfolio-db-backups-storage/

if [ $? -ne 0 ]; then
  echo "$DATE: failed to upload $FILENAME to S3" >>"$DUMPS_PATH/log.txt"
  exit
fi

echo "$DATE: Successfully uploaded file $FILENAME to S3" >>"$DUMPS_PATH/log.txt"
