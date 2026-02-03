# TRAE Manager

🔄 A macOS menu bar tool for managing multiple TRAE IDE accounts and preserving chat history.

## ✨ Features

- **Multi-Account Switching** - Seamlessly switch between TRAE accounts to maximize Token usage
- **Chat History Preservation** - Each profile maintains its own chat history
- **One-Click Operation** - Simple menu bar interface for instant switching
- **Profile Backup** - Save current session state anytime

## 🚀 Quick Start

### Installation

```bash
# Clone or download to your preferred location
cd ~/trae-manager

# Make the CLI tool executable
chmod +x scripts/trae-mgr

# Optional: Add to PATH
echo 'export PATH="$HOME/trae-manager/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Basic Usage

```bash
# Save your current TRAE session as a profile
trae-mgr save my_google_account_1

# Create an empty profile for a new account
trae-mgr create my_google_account_2

# List all profiles
trae-mgr list

# Switch to a different profile (will restart TRAE)
trae-mgr switch my_google_account_2

# Show current active profile
trae-mgr current
```

## 📋 Commands

| Command | Description |
|---------|-------------|
| `trae-mgr list` | List all saved profiles |
| `trae-mgr create <name>` | Create an empty profile |
| `trae-mgr save <name>` | Save current session as a profile |
| `trae-mgr switch <name>` | Switch to a specific profile |
| `trae-mgr delete <name>` | Delete a profile |
| `trae-mgr current` | Show current active profile |
| `trae-mgr help` | Display help information |

## 🔧 How It Works

TRAE Manager uses a **profile-based symlink approach**:

1. Each profile is a complete copy of TRAE's data directory
2. The actual TRAE data path (`~/Library/Application Support/Trae`) becomes a symlink
3. Switching profiles = updating the symlink target

```
~/.trae-manager/profiles/
├── account_google_1/    # Profile 1 (complete TRAE data)
├── account_google_2/    # Profile 2 (complete TRAE data)
└── default/             # Backup of original data

~/Library/Application Support/Trae  →  ~/.trae-manager/profiles/account_google_1
```

## ⚠️ Important Notes

1. **TRAE must be closed** before switching profiles
2. **Backup your data** before first use
3. Requires **macOS 13.0+**

## 🛠️ Development

See [DEVELOPMENT_PLAN.md](./DEVELOPMENT_PLAN.md) for detailed development roadmap.

## 📜 License

MIT License
