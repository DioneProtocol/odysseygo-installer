# Odysseygo install script

## Requirements
- `curl` - if this package is missing, the script will try to install it
- `wget` - if this package is missing, the script will try to install it
- `dnsutils` - if this package is missing, the script will try to install it
Packages required when using the `--version` flag:
- `gcc`- if this package is missing, you need to install it yourself
- `go` - if this package is missing, you need to install it yourself
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