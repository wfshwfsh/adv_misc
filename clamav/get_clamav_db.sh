#!/bin/bash

PATH_CLAMAV_DB="/var/lib/clamav/"
PATH_PATCH_DB="./database"

function check_clamav_db_size
{
    DB_SIZE_MB=$(du -sm "$PATH_CLAMAV_DB" | cut -f1)
    echo "$DB_SIZE_MB"
}

# Check network ability
ping -c 1 8.8.8.8 >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
    echo "Failed to connect to network"
    exit 1
fi

# Check clamav exist
if ! command -v clamscan > /dev/null 2>&1; then
    echo "clamav NOT installed"
    exit 1
fi

# Check is db folder exist
if [ ! -d "$PATH_CLAMAV_DB" ]; then
    mkdir $PATH_CLAMAV_DB
fi

# Manual download clamav database
sudo systemctl stop clamav-freshclam.service
sudo freshclam

PATH_CLAMAV_DB_SIZE=$(check_clamav_db_size)
if [ "$PATH_CLAMAV_DB_SIZE" -lt 50 ]; then
    echo "clamav database size not in expected"
    exit 1
fi

# Save to current folder
cp "$PATH_CLAMAV_DB"/* "$PATH_PATCH_DB"

echo "Success to download clamav database"



