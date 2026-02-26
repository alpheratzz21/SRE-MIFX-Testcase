#!/bin/bash
set -e

# Configuration : change these variables as needed
LOG_DIR="/var/log/myapp" # Directory where logs are stored
ARCHIVE_DIR="/var/log/myapp/archive" # Directory to store archived logs
MAX_SIZE=5242880 # 5 MB in bytes (5 * 1024 * 1024)
SCRIPT_LOG="/var/log/logrotate_script.log" #log activity of this script

# Create folder archive if it doesn't exist
mkdir -p $ARCHIVE_DIR

# Function for writing logs with timestamps
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] %1" | tee -a $SCRIPT_LOG
}

log "Starting check for log in $LOG_DIR"

# Loop all file .log in LOG_DIR
for file in $LOG_DIR/*.log; do
    #Skip if no log file is found
    [ -f "$file" ] || continue

    # Using file size in bytes
    size=$(stat -c%s "$file")
    filename=$(basename "$file")

    #Check if file size above the limit
    if [ $size -gt $MAX_SIZE ]; then
        # Create archive name with timestamp
        archive_name="${filename%.log}_$(date '+%Y%m%d%H%M%S').log.gz"
        
        log "Archiving $filename (size: $size bytes) to $archive_name"

        #Compress and store to archive directory
        gzip -c "$file" > "$ARCHIVE_DIR/$archive_name"

        log "Emptying $filename"

        # Empty file without deleting it
        truncate -s 0 "$file"

        log "Finished: $filename archived as $archive_name"
    else
        log "Skip $filename (size: $size bytes), below threshold"
    fi
done

log "Log rotation completed."
