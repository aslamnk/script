#!/bin/bash

# MySQL Database Details
DB_USER="db_user"
DB_PASSWORD="db_passwd"
DB_NAME="db_name"

# S3 Bucket Details
S3_BUCKET="s3://s3bucketname"
BACKUP_FOLDER="db_backups"

# Timestamp for Backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_$TIMESTAMP.sql"

# MySQL Backup
mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_FILE

# Check if the backup was successful
if [ $? -eq 0 ]; then
  echo "MySQL Backup Successful."

  # Upload to S3
  aws s3 cp $BACKUP_FILE $S3_BUCKET/$BACKUP_FOLDER/

  # Check if the upload was successful
  if [ $? -eq 0 ]; then
    echo "Backup uploaded to S3 successfully."

    # Delete the local backup file
    rm $BACKUP_FILE
    echo "Local backup file deleted."
  else
    echo "Error uploading backup to S3. Please check AWS CLI configuration and try again."
  fi
else
  echo "Error creating MySQL backup. Please check MySQL credentials and try again."
fi
