#!/bin/bash

# Start ArcGIS Server (this runs and exits, leaving the server daemonized)
/home/arcgis/server/startserver.sh

# Give the server a moment to generate the initial directories and logs
sleep 15

LOG_DIR="/home/arcgis/server/usr/logs/LOCALHOST/server"
CURRENT_LOG=""

# Keep the container alive and monitor for new log files
while true; do
    # Find the most recently modified log file, suppressing errors if none exist yet
    LATEST_LOG=$(ls -t "$LOG_DIR"/server-*.log 2>/dev/null | head -n 1)

    # If a new log file is detected
    if [ "$LATEST_LOG" != "$CURRENT_LOG" ] && [ -n "$LATEST_LOG" ]; then
        # Kill the previous tail process if it exists
        if [ -n "$TAIL_PID" ]; then
            kill $TAIL_PID 2>/dev/null
        fi
        
        CURRENT_LOG="$LATEST_LOG"
        echo "--> Now tailing active log: $CURRENT_LOG"
        
        # Start tailing the new log in the background
        tail -f "$CURRENT_LOG" &
        
        # Capture the process ID of the new tail command
        TAIL_PID=$!
    fi
    
    # Wait 10 seconds before checking for a new log file again
    sleep 10
done
