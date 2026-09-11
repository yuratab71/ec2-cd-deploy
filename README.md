# Example of deploying the dockerized application into ec2

# Original application

- Ghostfolio [here](https://github.com/ghostfolio/ghostfolio)

# Steps

- terraform plan
- terraform apply
- Get the nameservers from terraform output and add the to the Domain provider custom NS configuration
- Get the IP of running instance
- SSH to ec2
- Run following script to allow execute the scripts and run them

```bash
chmod 755 postinstall.bash setup-chron-archiver.bash archive-backup.bash

sudo ./postinstall.bash && sudo ./setup-cron-archiver.bash
```
