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
./odysseygo-installer.sh --version develop --testnet
```
