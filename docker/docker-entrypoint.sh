#!/bin/sh
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


echo "LazyMC_For_Crafty version: ${CONTAINER_BUILD_VERSION}"



##################################
## CHECK IF ENVIRONMENT VARIABLES ARE CONFIGURED
##################################
echo "Initialization.."
EMPTY_ENV=""
if [ -z "$CRAFTY_IP" ]; then
    EMPTY_ENV=$EMPTY_ENV"CRAFTY_IP "
fi
if [ -z "$CRAFTY_PORT" ]; then
    EMPTY_ENV=$EMPTY_ENV"CRAFTY_PORT "
fi
if [ -z "$CRAFTY_API_KEY" ]; then
    EMPTY_ENV=$EMPTY_ENV"CRAFTY_API_KEY "
fi
if [ -z "$LAZYMC_PUBLIC_IP" ]; then
    EMPTY_ENV=$EMPTY_ENV"LAZYMC_PUBLIC_IP "
fi

for var in $EMPTY_ENV; do
    echo "Environment variable $var is not assigned. Please configure it before restarting the container."
done
if ! [ -z "$EMPTY_ENV" ]; then
    echo "Shutting down.."
    sleep 5
    exit 1
fi



##################################
## CREATE LIST OF SERVERS IN CRAFTY
##################################
serverDir=/crafty/servers
serversListe=
for server in "${serverDir}"/*; do
    [ -d "$server" ] || continue
    serversListe="$serversListe ${server##*/}"
done



##################################
## CREATE LAZYMC CONF FOR EACH SERVER
##################################
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        cp /lazymc/lazymc-template.toml /lazymc/lazymc-"${dir}".toml
        sed -i -e "s/REPLACE_PUBLIC_IP/$LAZYMC_PUBLIC_IP/" /lazymc/lazymc-"${dir}".toml
        sed -i -e "s/REPLACE_SERVER_IP/$CRAFTY_IP/" /lazymc/lazymc-"${dir}".toml
        sed -i -e "s/REPLACE_DIRECTORY/\/crafty\/servers\/${dir}/" /lazymc/lazymc-"${dir}".toml
        sed -i -e "s/REPLACE_COMMAND/sh \/lazymc\/start.sh ${dir}/" /lazymc/lazymc-"${dir}".toml
    fi
done



##################################
## EDIT CONF WITH UNIQUE VALUE FOR EACH SERVER
##################################
BASE_PORT=25445
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        # Assigne unique port
        BASE_PORT=$((BASE_PORT+1))
        sed -i -e "s/REPLACE_SERVER_PORT/$BASE_PORT/" /lazymc/lazymc-"${dir}".toml

        # Assigne unique public port
        varName_publicPORT="lazymc_PUBLIC_PORT_${dir}"
        # Retrieve variable value from ENV
        value_publicPORT=$(printenv "$varName_publicPORT")
        # If variable exist in ENV exist then
        if [ -n "$value_publicPORT" ]; then
            sed -i -e "s/REPLACE_PUBLIC_PORT/$value_publicPORT/" /lazymc/lazymc-"${dir}".toml
        fi

        # Assigne unique server version
        varName_serverVersion="lazymc_SERVER_VERSION_${dir}"
        # Retrieve variable value from ENV
        value_serverVersion=$(printenv "$varName_serverVersion")
        # If variable exist in ENV exist then
        if [ -n "$value_serverVersion" ]; then
            sed -i -e "s/REPLACE_VERRSION/$value_serverVersion/" /lazymc/lazymc-"${dir}".toml
        fi

        # Assigne unique server protocole
        varName_serverProtocole="lazymc_PROTOCOLE_VERSION_${dir}"
        # Retrieve variable value from ENV
        value_serverProtocole=$(printenv "$varName_serverProtocole")
        # If variable exist in ENV exist then
        if [ -n "$value_serverProtocole" ]; then
            sed -i -e "s/REPLACE_PROTOCOLE/$value_serverProtocole/" /lazymc/lazymc-"${dir}".toml
        fi
    fi
done



##################################
## START ONE LAZYMC SUBPROCESS BY SERVER
##################################
echo "Initialization complete"
for dir in ${serversListe}; do
    # Check if the enable variable exists AND if it is true
    varName_enable="lazymc_ENABLE_${dir}"
    value_enable=$(printenv "$varName_enable" 2>/dev/null || true)
    if [ -n "$value_enable" ] && [ "$value_enable" = "true" ]; then

        lazymc --config /lazymc/lazymc-"${dir}".toml &
        pids="$pids $!"
    fi
done

wait
exit 0
