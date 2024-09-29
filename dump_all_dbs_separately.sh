#!/bin/bash

# Database connection parameters
HOST="compliance-careezy-dev-stagging.cufnrrhslbyc.eu-west-1.rds.amazonaws.com"
USER="postgres"
# Uncomment and set the password if required
# PGPASSWORD="your_password"
# export PGPASSWORD

# Excluded databases (system DBs)
EXCLUDED_DBS="template0 template1 postgres rdsadmin"

# Output file for the list of backed up databases
BACKUP_LIST_FILE="backed_up_databases.txt"
# Clear the content of the file if it exists
> $BACKUP_LIST_FILE

# Get the list of databases excluding the system ones
DB_LIST=$(psql -h $HOST -U $USER -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ($(
    echo $EXCLUDED_DBS | sed "s/ /','/g" | sed "s/^/'/" | sed "s/$/'/"
))")

# Loop over each database and dump it into a separate file
for DB in $DB_LIST; do
    DB=$(echo $DB | xargs)  # Trim any extra whitespace
    echo "Dumping database: $DB"
    
    # Take dump
    pg_dump -h $HOST -U $USER -F c -d $DB -f "${DB}_dump.sql"
    
    if [ $? -eq 0 ]; then
        echo "Successfully dumped $DB to ${DB}_dump.sql"
        
        # Add the database name to the backup list file
        echo $DB >> $BACKUP_LIST_FILE
    else
        echo "Failed to dump $DB"
    fi
done

echo "Backup completed. Databases saved to $BACKUP_LIST_FILE."
