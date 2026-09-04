#!/bin/bash

# EXAMPLE SETUP CRON JOB TO ARCHIVE THE PG DUMP, JUST RUN AFTER CREATING THE INSTANCE

set -e

aws configure

mkdir /home/ubuntu/dumps

chmod 755 /home/ubuntu/archive-backup.bash

crontab -l 2>/dev/null
echo "0 3 * * 5 /home/ubuntu/archive-backup.bash" | crontab -
