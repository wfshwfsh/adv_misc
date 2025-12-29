#!/bin/bash

PATH_CLAMAV_DB="/var/lib/clamav/"
PATH_PATCH_DB="./database"

# Check database exist: exit script if not exist
if [ ! -d "$PATH_PATCH_DB" ]; then
    echo "folder NOT exist: $PATH_PATCH_DB"
    exit 1
fi

# Calculate database size(unit: MB)
DIR_SIZE_MB=$(du -sm "$PATH_PATCH_DB" | cut -f1)
if [ "$DIR_SIZE_MB" -lt 50 ]; then
    echo "database size not in expected"
    exit 1
fi

# Stop freshclam
sudo systemctl stop clamav-freshclam.service

# install database
sudo cp "$PATH_PATCH_DB"/* "$PATH_CLAMAV_DB"

# Restart clamav-freshclam
sudo systemctl restart clamav-freshclam

# Restart clamav
sudo systemctl restart clamav-daemon.service

