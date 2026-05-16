#!/bin/bash

echo "Starting ArcGIS Server daemon..."
/home/arcgis/server/startserver.sh

echo "Waiting for local ArcGIS Server to initialize..."
until curl -s -k -o /dev/null https://localhost:6443/arcgis/manager; do
    sleep 5
done

CONFIG_STORE="/home/arcgis/server/usr/config-store"
HOSTNAME=$(hostname)

# ---------------------------------------------------------
# 1. SITE INITIALIZATION / JOIN LOGIC
# ---------------------------------------------------------
if [ ! -d "$CONFIG_STORE/machines" ]; then
    echo "--> Blank config-store detected. Creating new site..."
    curl -s -k -X POST https://localhost:6443/arcgis/admin/createNewSite \
        -d "username=${ARCGIS_ADMIN_USER}" \
        -d "password=${ARCGIS_ADMIN_PASS}" \
        -d "f=json"
elif [ ! -f "$CONFIG_STORE/machines/${HOSTNAME}.json" ]; then
    if [ -n "$PRIMARY_MACHINE_URL" ]; then
        echo "--> Machine ${HOSTNAME} is not registered. Joining site..."
        curl -s -k -X POST https://localhost:6443/arcgis/admin/joinSite \
            -d "adminURL=${PRIMARY_MACHINE_URL}" \
            -d "username=${ARCGIS_ADMIN_USER}" \
            -d "password=${ARCGIS_ADMIN_PASS}" \
            -d "f=json"
        sleep 15
    else
        echo "--> WARNING: PRIMARY_MACHINE_URL not set. Cannot join existing site."
    fi
fi

# ---------------------------------------------------------
# 2. CONTINUOUS LOOP: LOGS & GARBAGE COLLECTION
# ---------------------------------------------------------
LOG_DIR="/home/arcgis/server/usr/logs/LOCALHOST/server"
CURRENT_LOG=""

LAST_CLEANUP=$(date +%s)
CLEANUP_INTERVAL=300 # 5 minutes

while true; do
    CURRENT_TIME=$(date +%s)

    # --- Ghost Node Cleanup ---
    if [ $((CURRENT_TIME - LAST_CLEANUP)) -ge $CLEANUP_INTERVAL ] && [ -n "$PRIMARY_MACHINE_URL" ]; then
        
        TOKEN=$(curl -s -k -X POST "${PRIMARY_MACHINE_URL}/generateToken" \
            -d "username=${ARCGIS_ADMIN_USER}" \
            -d "password=${ARCGIS_ADMIN_PASS}" \
            -d "client=requestip" \
            -d "expiration=5" \
            -d "f=json" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

        if [ -n "$TOKEN" ]; then
            MACHINES=$(curl -s -k -X POST "${PRIMARY_MACHINE_URL}/machines" \
                -d "token=${TOKEN}" \
                -d "f=json" | grep -o '"machineName":"[^"]*' | cut -d'"' -f4)

            for MACHINE in $MACHINES; do
                if [ "$MACHINE" != "arcgis-primary" ] && [ "$MACHINE" != "$HOSTNAME" ]; then
                    
                    STATUS=$(curl -s -k -X POST "${PRIMARY_MACHINE_URL}/machines/${MACHINE}/status" \
                        -d "token=${TOKEN}" \
                        -d "f=json" | sed -n 's/.*"realTimeState":"\([^"]*\)".*/\1/p')

                    # Remove if not STARTED or STARTING
                    if [[ "$STATUS" != "STARTED" && "$STATUS" != "STARTING" ]]; then
                        echo "--> Node $MACHINE state is $STATUS. Unregistering..."
                        curl -s -k -X POST "${PRIMARY_MACHINE_URL}/machines/${MACHINE}/unregister" \
                            -d "token=${TOKEN}" \
                            -d "f=json"
                    fi
                fi
            done
        fi
        LAST_CLEANUP=$CURRENT_TIME
    fi

    # --- Dynamic Log Tailing ---
    LATEST_LOG=$(ls -t "$LOG_DIR"/server-*.log 2>/dev/null | head -n 1)

    if [ "$LATEST_LOG" != "$CURRENT_LOG" ] && [ -n "$LATEST_LOG" ]; then
        [ -n "$TAIL_PID" ] && kill $TAIL_PID 2>/dev/null
        CURRENT_LOG="$LATEST_LOG"
        tail -f "$CURRENT_LOG" &
        TAIL_PID=$!
    fi
    
    sleep 10
done
