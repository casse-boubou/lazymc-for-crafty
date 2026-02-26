#!bin/sh
set -e # Exit immediately if a command exits with a non-zero status.
## INIT
# Set list of pid for each sub-process
pids=""
# Create fonction for kill each sub process
term_handler() {
  echo "Received stop signal, shutting down..."
  for pid in $pids; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  wait
  exit 0
}
# Handle exit signal from Docker
trap term_handler TERM INT



# Create liste of servers in crafty
serverDir=/crafty/servers
serversListe=
for server in $(ls ${serverDir}); do
    serversListe="$serversListe $server"
done



# Create lazymc conf for each server
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        cp /lazymc/lazymc-template.toml /lazymc/lazymc-${dir}.toml
        sed -i -e "s/REPLACE_PUBLIC_IP/$lazymc_PUBLIC_IP/" /lazymc/lazymc-${dir}.toml
        sed -i -e "s/REPLACE_SERVER_IP/$CRAFTY_IP/" /lazymc/lazymc-${dir}.toml
        sed -i -e "s/REPLACE_DIRECTORY/\/crafty\/servers\/${dir}/" /lazymc/lazymc-${dir}.toml
        sed -i -e "s/REPLACE_COMMAND/sh \/lazymc\/start.sh ${dir}/" /lazymc/lazymc-${dir}.toml
    fi
done



# Edit conf with unique value for each server
BASE_PORT=25445
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        # Assigne unique port
        BASE_PORT=$((BASE_PORT+1))
        sed -i -e "s/REPLACE_SERVER_PORT/$BASE_PORT/" /lazymc/lazymc-${dir}.toml

        # Assigne unique public port
        varName_publicPORT="lazymc_PUBLIC_PORT_${dir}"
        # Retrieve variable value from ENV
        value_publicPORT=$(printenv "$varName_publicPORT")
        # If variable exist in ENV exist then
        if [ -n "$value_publicPORT" ]; then
            sed -i -e "s/REPLACE_PUBLIC_PORT/$value_publicPORT/" /lazymc/lazymc-${dir}.toml
        fi

        # Assigne unique server version
        varName_serverVersion="lazymc_SERVER_VERSION_${dir}"
        # Retrieve variable value from ENV
        value_serverVersion=$(printenv "$varName_serverVersion")
        # If variable exist in ENV exist then
        if [ -n "$value_serverVersion" ]; then
            sed -i -e "s/REPLACE_VERRSION/$value_serverVersion/" /lazymc/lazymc-${dir}.toml
        fi

        # Assigne unique server protocole
        varName_serverProtocole="lazymc_PROTOCOLE_VERSION_${dir}"
        # Retrieve variable value from ENV
        value_serverProtocole=$(printenv "$varName_serverProtocole")
        # If variable exist in ENV exist then
        if [ -n "$value_serverProtocole" ]; then
            sed -i -e "s/REPLACE_PROTOCOLE/$value_serverProtocole/" /lazymc/lazymc-${dir}.toml
        fi
    fi
done



# Launch one lazymc subprocess by server
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        lazymc --config /lazymc/lazymc-${dir}.toml &
        pids="$pids $!"
    fi
done

wait
exit 0
