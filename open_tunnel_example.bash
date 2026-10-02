#!/bin/bash

set -e
set -x

ssh -N -i ~/.ssh/terraform-key -L 5432:_database_host_:5432 ubuntu@yuratab-db.pp.ua
