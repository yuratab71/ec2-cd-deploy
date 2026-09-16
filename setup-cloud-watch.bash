#!/bin/bash

#EXAMPLE SCRIPT TO SETUP AWS CLOUD WATCH ON EC2 ISNTANCE

set -e
set -x

WORKDIR="/home/ubuntu"
CONFIG="cloudwatch-config.json"

cd $WORKDIR

curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

sudo dpkg -i amazon-cloudwatch-agent.deb

sudo tee $WORKDIR/$CONFIG <<EOF
{
  "agent": {
     "metrics_collection_interval": 60,
     "region": "us-east-1"
   },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/ec2/ghostfolio/nginx_access",
            "log_stream_name": "ghostfolio",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/ec2/ghostfolio/nginx_error",
            "log_stream_name": "ghostfolio",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/lib/docker/containers/*/*-json.log",
            "log_group_name": "/ec2/ghostfolio/app",
            "log_stream_name": "ghostfolio",
            "timezone": "UTC"

          }
        ]
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:$WORKDIR/$CONFIG

sudo systemctl enable amazon-cloudwatch-agent.service --now
