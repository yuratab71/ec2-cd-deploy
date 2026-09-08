# Example of deploying the dockerized application into ec2

# Original application

- Ghostfolio [here](https://github.com/ghostfolio/ghostfolio)

# Steps

- terraform plan
- terraform apply
- Get the nameservers from terraform output and add the to the Domain provider custom NS configuration
- Get the IP of running instance
- SSH to ec2
- Run following script to allow execute the scripts

```bash
chmod 755 bootstrap.bash
chmod 755 postinstall.bash
chmod 755 setup-cron-archiver.bash
chmod 755 setup-backup-archiver.bash
```

- And execute the scripts itself

```bash
sudo ./bootstrap.bash
sudo ./postinstall.bash.bash
sudo ./setup-cron-archiver.bash.bash
```
