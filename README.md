# Odysseygo install script

## Requirements
- supported operating systems: 
    - RHEL (Red Hat Enterprise Linux)
    - all Debian-based Linux distributions (Debian, mint, Ubuntu, etc.)
- `curl` - if this package is missing, the script will try to install it
- `wget` - if this package is missing, the script will try to install it
- `dnsutils` - if this package is missing, the script will try to install it
Packages required when using the `--version` flag:
- `gcc`- if this package is missing, you need to install it yourself
- `go` - if this package is missing, you need to install it yourself (version >= 1.20.8)
- `git` - if this package is missing, you need to install it yourself

## Examples
### For instructions, enter the command:
```bash
./odysseygo-installer.sh --help
```

### Install the latest release of the odysseygo for the mainnet:
```bash
./odysseygo-installer.sh
```

### Install the odysseygo from develop branch for the mainnet:
```bash
./odysseygo-installer.sh --version develop
```

### Install the latest release of the odysseygo for the testnet:
```bash
./odysseygo-installer.sh --testnet
```

### Install the odysseygo from develop branch for the testnet:
```bash
./odysseygo-installer.sh --testnet --version develop 
```

```
Usage: ./odysseygo-installer.sh [--list | --help | --reinstall | --remove] [--version <tag>] [--ip dynamic|static|<IP>]
                     [--rpc private|public] [--archival] [--state-sync on|off] [--index] [--db-dir <path>]
Options:
   --help            Shows this message
   --list            Lists 10 newest versions available to install
   --reinstall       Run the installer from scratch, overwriting the old service file and node configuration
   --remove          Remove the system service and OdysseyGo binaries and exit

   --version <tag>             Installs <tag> version, default is the latest
   --ip dynamic|static|<IP>    Uses dynamic, static (autodetect) or provided public IP, will ask if not provided
   --rpc private|public        Open RPC port (9650) to private or public network interfaces, will ask if not provided
   --archival                  If provided, will disable state pruning, defaults to pruning enabled
   --state-sync on|off         If provided explicitly turns D-Chain state sync on or off
   --index                     If provided, will enable indexer and Index API, defaults to disabled
   --log-level-node <level>    Node log level, defaults to info
   --log-level-d-chain <level> D-chain log level, defaults to info
   --db-dir <path>             Full path to the database directory, defaults to .odysseygo/db
   --testnet                   Connect to testnet, defaults to mainnet if omitted
   --admin                     Enable Admin API, defaults to disabled if omitted
   --eth-debug-rpc             Enable Debug API, defaults to disabled if omitted

Run without any options, script will install or upgrade OdysseyGo to latest available version. Node config
options for version, ip and others will be ignored when upgrading the node, run with --reinstall to change config.
Reinstall will not modify the database or NodeID definition, it will overwrite node and chain configs.
```
