# lazymc-for-crafty

lazymc-for-crafty is a Docker container that integrates LazyMC with Crafty Controller 4 in order to automatically start and stop your Minecraft servers on demand.

It acts as an intelligent proxy between players and the Minecraft servers managed by Crafty.

## What it does

- Exposes public Minecraft ports (25565, 25566, etc.).

- Intercepts incoming player connections.

- Automatically starts the corresponding Crafty-managed server if it is offline.

- Forwards traffic to the real Minecraft server once it is ready.

- Stops the server again when it becomes empty.

This allows you to run multiple Minecraft servers without keeping them permanently online. Reduce CPU and RAM usage when servers are idle and keep a single public entry point per server.

## How It Works

When A player connects to a public port exposed by lazymc_crafty4, lazymc checks whether the target server is running. If the server is stopped, the container uses the Crafty API to start it.

Lazymc waits until the server is readyand proxied the connexion to the actual Minecraft server instance.

If no players remain connected for 5 minutes, the server can be stopped automatically.

# Installation

### First step

- Install crafty4 and access the dashboard

- Create a Role in the crafty `Panel settings`, give it a name (e.g. `commandAccess`) and assign your user account for manager for this role.

- Go to your user account settings, then to the API Keys panel and Create a new API token with `COMMANDS` permission. Save this token somewhere; it will be used later for the `CRAFTY_API_KEY` environment variable.

### Second step

- Create new server, give it name and select your Role create in step one in `Add Server to Existing Role` section

- Wait for the server to be created, launch it once to accept the EULA rules, then stop it.

- Save the `server's UUID` somewhere; it will be used later in the environment variables. 

- In the server's `config` panel, replace

  - `Server IP` with the IP address of your future lazymc_crafty4 service (e.g. `lazymc_crafty4` if the service is in the same stack as crafty4).
  - `Server Port` with the port you want to assign to the server

### Third step

- Add lazymc_crafty4 to your `docker-compose.yml` next to crafty.

```yaml
services:
  # Your existing crafty instance
  crafty:
      container_name: crafty
      image: registry.gitlab.com/crafty-controller/crafty-4:latest
      restart: always
      environment:
          - TZ=Etc/UTC
      ports:
          - "8443:8443" # HTTPS PANEL ACCESS
          - "8123:8123" # DYNMAP (optional)
        #   MC SERV PORT RANGE is not need here because we proxy it in lazymc_crafty4
        #   - "25500-25600:25500-25600" # MC SERV PORT RANGE
      volumes:
          - ./docker/backups:/crafty/backups
          - ./docker/logs:/crafty/logs
          - ./docker/servers:/crafty/servers
          - ./docker/config:/crafty/app/config
          - ./docker/import:/crafty/import


  lazymc_crafty4:
    container_name: lazymc_crafty4
    image: ghcr.io/casse-boubou/lazymc-for-crafty:latest
    environment:
      - CRAFTY_IP=crafty                        # name of crafty container in network
      - CRAFTY_PORT=8443                        # port of crafty container in network
      - CRAFTY_API_KEY=${lazymc_CRAFTY_API_KEY} # ApiKey with COMMANDS acces
      - lazymc_PUBLIC_IP=lazymc_crafty4         # name of this container (lazymc_crafty4) in network
        # SERVER 1
      - lazymc_ENABLE_UUID1=true                # Replace UUID1 with UUID of server in crafty
      - lazymc_PUBLIC_PORT_UUID1=25565          # Replace UUID1 with UUID of server in crafty
      - lazymc_SERVER_VERSION_UUID1=1.21.10     # Replace UUID1 with UUID of server in crafty
      - lazymc_PROTOCOLE_VERSION_UUID1=773      # Replace UUID1 with UUID of server in crafty
        # SERVER 2
      - lazymc_ENABLE_UUID2=true
      - lazymc_PUBLIC_PORT_UUID2=25566
      - lazymc_SERVER_VERSION_UUID2=1.21.11
      - lazymc_PROTOCOLE_VERSION_UUID2=774
        # SERVER X...
    volumes:
      - /path/to/your/crafty/servers:/crafty/servers
    ports:
      - 25565:25565 # Minecraft servers 1
      - 25566:25566 # Minecraft servers 2
      - ....:....   # Minecraft servers X...
```

For protocol version you can take a look [in this website](https://fr.minecraft.wiki/w/Version_de_protocole)

- Restart your stack and enjoy

# Configuration Options

## Required

### Bind port for each server

To function, lazymc acts as a proxy between the server access ports and your server ports in crafty4.
You will therefore need to set up your ports here and not in crafty.

```yaml
services:
  lazymc_crafty4:
    ....
    ports:
      - 25565:25565 # Minecraft servers 1
      - 25566:25566 # Minecraft servers 2
      - ....:....   # Minecraft servers X...
```

### Configure environment

Environment variables are required and must be configured as follows:

```yaml
services:
  lazymc_crafty4:
    ....
    environment:
      - CRAFTY_IP=crafty                        # name of crafty container in network
      - CRAFTY_PORT=8443                        # port of crafty container in network
      - CRAFTY_API_KEY=${lazymc_CRAFTY_API_KEY} # ApiKey with COMMANDS acces
      - lazymc_PUBLIC_IP=lazymc_crafty4         # name of this container (lazymc_crafty4) in network
        # SERVER 1
      - lazymc_PUBLIC_PORT_UUID1=25565          # End of VAR is UUID of server in crafty
      - lazymc_SERVER_VERSION_UUID1=1.21.10     # End of VAR is UUID of server in crafty
      - lazymc_PROTOCOLE_VERSION_UUID1=773      # End of VAR is UUID of server in crafty
        # SERVER 2
      - lazymc_PUBLIC_PORT_UUID2=25566
      - lazymc_SERVER_VERSION_UUID2=1.21.11
      - lazymc_PROTOCOLE_VERSION_UUID2=774
        # SERVER X...
```

### Mount Crafty servers folder

Mount your crafty servers folder inside /crafty/servers:

```yaml
services:
  lazymc_crafty4:
    ....
    volumes:
      - /path/to/your/crafty/servers:/crafty/servers
```

## Optional

### Configure the default values for lazymc

If you wish, you can edit the default configuration of lazymc as indicated in [the github project](https://github.com/timvisee/lazymc/blob/master/res/lazymc.toml) BUT be careful to keep the following lines intact and put them back in place:

```toml
[public]
address = "REPLACE_PUBLIC_IP:REPLACE_PUBLIC_PORT"
version = "REPLACE_VERRSION"
protocol = REPLACE_PROTOCOLE

[server]
address = "REPLACE_SERVER_IP:REPLACE_SERVER_PORT"
directory = "REPLACE_DIRECTORY"
command = "REPLACE_COMMAND"
```

Create your configuration file.toml and mount it as a volume like this

```yaml
services:
  lazymc_crafty4:
    ....
    volumes:
      - /path/to/your/file.toml:/lazymc/lazymc-template.toml:ro
```

### Healthcheck

The container includes a built-in healthcheck.
By default, it is configured to be checked every 30 seconds.

You can fully customize or override the healthcheck in your docker-compose.yml.

```yaml
services:
  lazymc_crafty4:
    ....
    healthcheck:
      test: pgrep -f "lazymc --config" > /dev/null || exit 1
      interval: 10m
      timeout: 30s
      retries: 10
      start_period: 60s
      start_interval: 5s
```
