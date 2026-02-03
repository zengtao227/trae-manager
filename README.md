# TRAE Manager

<p align="center">
  <img src="scripts/TraeManager.png" alt="TRAE Manager Icon" width="128" />
  <br>
  <b>The Ultimate Account Switcher for TRAE IDE</b>
  <br>
  <br>
  <a href="https://github.com/zengtao227/trae-manager/issues">Report Bug</a>
  ·
  <a href="https://github.com/zengtao227/trae-manager/pulls">Request Feature</a>
</p>

---

## 📖 Introduction

**TRAE Manager** is a powerful utility designed to help developers manage multiple accounts in the [TRAE IDE](https://trae.ai). By allowing seamless switching between different profiles, you can maximize your AI model token quotas and keep your chat history organized and isolated for each account.

Whether you are a heavy user hitting daily limits or a consultant managing separate workspaces, TRAE Manager provides the flexibility you need on both **macOS** and **Windows**.

## ✨ Why Use TRAE Manager?

- **🚀 Maximize Token Limits**: Instantly switch to a secondary account when you hit your AI quota limit.
- **💬 Preserve Chat History**: Every profile has its own isolated chat history database. Switching accounts never wipes your past conversations.
- **🛡️ Data Safety**: Your original data is automatically backed up before the first switch.
- **⚡ Fast & Native**: 
  - **macOS**: A dedicated Menu Bar App for one-click switching.
  - **Windows**: A robust PowerShell script for easy management.

---

## 📦 Downloads & Installation

### 🍎 macOS (App & CLI)

**Option 1: Menu Bar App (Recommended)**
1. Go to the `release/` directory in this repository.
2. Drag **`TraeManager.app`** to your **Applications** folder.
3. Open the app. You will see a 👥 icon in your menu bar.

**Option 2: Build from Source**
```bash
cd ~/trae-manager/swift/TraeManager
./build.sh
open build/TraeManager.app
```

### 🪟 Windows (PowerShell)

1. Download `scripts/windows/trae-mgr.ps1`.
2. Open **PowerShell** as Administrator (recommended for first run).
3. Allow script execution if needed:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
4. Run the script:
   ```powershell
   .\trae-mgr.ps1 help
   ```

---

## 🎮 Usage Guide

### macOS Menu Bar App

1. **Check Status**: Click the menu bar icon to see your current profile and TRAE running status.
2. **Save Session**: Click **"Save Current Session..."** to save your current working state as a new profile (e.g., `work_account`).
3. **Switch**: Select any saved profile from the list to switch. **TRAE will restart automatically.**
4. **Manage**: You can Create, Rename, Duplicate, or Delete profiles directly from the menu.
5. **Auto-Start**: Go to **Settings > Launch at Login** to have TRAE Manager ready when you start your Mac.

### Command Line Interface (CLI)

Both macOS (`trae-mgr`) and Windows (`trae-mgr.ps1`) support the same command structure.

| Command | Description | Example |
|---------|-------------|---------|
| `save` | Save current TRAE data as a named profile | `trae-mgr save google_acc` |
| `create` | Create a brand new, empty profile | `trae-mgr create fresh_start` |
| `switch` | Switch to a specific profile (Restarts TRAE) | `trae-mgr switch google_acc` |
| `list` | Show all saved profiles and their sizes | `trae-mgr list` |
| `current` | Display the name of the active profile | `trae-mgr current` |
| `delete` | Remove a profile permanently | `trae-mgr delete old_acc` |
| `backup` | Backup the original TRAE data | `trae-mgr backup` |

#### Example Workflow
```bash
# 1. Save your existing main account
trae-mgr save main_account

# 2. Create a new profile for a second account
trae-mgr create second_account

# 3. Switch to the new account (TRAE restarts, ask you to login)
trae-mgr switch second_account

# ... Login with your second email in TRAE ...

# 4. Switch back anytime
trae-mgr switch main_account
```

---

## 🔧 How It Works

TRAE Manager uses a **Symbolic Link (Symlink)** strategy to manage your data without moving gigabytes of files around constantly.

1. **Storage**: All your profiles are stored in `~/.trae-manager/profiles/`.
2. **Linking**: The actual TRAE data directory (`~/Library/Application Support/Trae` on Mac, `%APPDATA%\Trae` on Windows) is replaced by a link pointing to the active profile folder.
3. **Switching**: When you switch profiles, the tool simply updates where the link points to.

Reference path structure:
```
~/.trae-manager/profiles/
├── main_account/       <-- Profile A data
├── second_account/     <-- Profile B data
└── default/            <-- Original Backup

# The link:
Actual_Trae_Path  ➡️  ~/.trae-manager/profiles/main_account
```

---

## ❓ FAQ

**Q: Will I lose my data?**
A: No. When you first run a switch command, TRAE Manager automatically backs up your existing data to a profile named `default` (or `default` folder). However, we always recommend making a manual backup if your data is critical.

**Q: Can I run this while TRAE is open?**
A: The tool will automatically close TRAE before switching profiles to prevent data corruption. It will then restart TRAE for you.

**Q: Where are my profiles stored?**
A: 
- macOS: `~/.trae-manager/profiles/`
- Windows: `C:\Users\<User>\.trae-manager\profiles\`

---

## 📜 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

## 🙏 Acknowledgments

- Inspired by the concept of *Antigravity Manager*.
- Built with **SwiftUI** for macOS and **PowerShell** for Windows.
