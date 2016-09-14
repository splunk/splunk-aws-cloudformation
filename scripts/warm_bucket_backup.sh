#!/bin/bash
# warm_bucket_backup.sh

#- Splunk variables
splunk_db=/opt/splunk
warm_directory=$splunk_db/my_index/db

#- target s3 bucket for backups
s3_backup_bucket=backup-bucket-name

#- assuming s3 infrequent access storage class
aws s3 sync $warm_directory/db_* s3://$s3_backup_bucket --storage-class STANDARD_IA
