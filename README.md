# OdysseyGo Installer

A comprehensive installer and setup tool for running OdysseyGo nodes on the Odyssey network.

## 🚀 Quick Start

### For Validators (Recommended)

**Quick Setup with OdysseyJS (Easiest Method):**
```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker

# Run the automated setup script
./setup-validator-env.sh

# Start your validator node
docker-compose up -d
```

**🎉 That's it!** The setup script automatically:
- Creates validator-optimized configuration
- Sets up required directories
- Provides clear next steps for validator registration

For detailed validator setup instructions, see [docker/VALIDATOR_SETUP.md](docker/VALIDATOR_SETUP.md).

### For Archive Nodes

```bash
git clone https://github.com/DioneProtocol/odysseygo-installer/
cd odysseygo-installer/docker

# Create required directories
mkdir -p data/.odysseygo data/db logs

# Start with defaults (archive mode)
docker-compose up -d
```

## 📚 Documentation

- **[Docker Setup](docker/README.md)** - Complete Docker installation guide
- **[Validator Setup](docker/VALIDATOR_SETUP.md)** - Step-by-step validator configuration
- **[Validator Quick Setup](docker/VALIDATOR_ODYSSEYJS_SETUP.md)** - Simplified OdysseyJS-based setup

## 🔧 Features

- **Automatic Bootstrap Download** - Downloads and extracts bootstrap data automatically
- **Validator-Optimized** - Fast state sync with minimal storage requirements
- **Archive Mode Support** - Full blockchain history for data providers
- **Cross-Platform** - Works on Linux, macOS, and Windows
- **Environment-Based Configuration** - Easy customization via .env files

## 🆕 What's New

- **Simplified Validator Setup** - New automated setup scripts for easy validator configuration
- **OdysseyJS Integration** - Clear, step-by-step validator registration following OdysseyJS patterns
- **Environment-First Approach** - Set all variables upfront, then run simple commands

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
