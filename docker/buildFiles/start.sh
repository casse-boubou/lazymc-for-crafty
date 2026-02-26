#!bin/bash

SERVER_ID="$1"

start_server () {
     wget --header="Authorization: Bearer $CRAFTY_API_KEY" \
          --post-data='' \
          --no-check-certificate \
          -O /dev/null \
          -q \
          https://$CRAFTY_IP:$CRAFTY_PORT/api/v2/servers/$SERVER_ID/action/start_server
}
stop_server () {
     wget --header="Authorization: Bearer $CRAFTY_API_KEY" \
          --post-data='' \
          --no-check-certificate \
          -O /dev/null \
          -q \
          https://$CRAFTY_IP:$CRAFTY_PORT/api/v2/servers/$SERVER_ID/action/stop_server
}
cleanup() {
    stop_server
    kill -TERM "$PID"
    wait "$PID"
    exit 0
}



# Trap SIGTERM, forward it to server process ID
trap cleanup TERM INT

# Start server
start_server

# Create a fake subprocess that lazymc will handle in order to simulate control of the server
sleep infinity &
# Remember sleep process ID, wait for it to quit
PID=$!
wait $PID