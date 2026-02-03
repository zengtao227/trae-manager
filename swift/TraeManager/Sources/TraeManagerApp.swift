import SwiftUI
import UserNotifications
import ServiceManagement

@main
struct TraeManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var profileManager: ProfileManager!
    var autoRefreshTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Initialize profile manager
        profileManager = ProfileManager()
        
        // Setup menu bar
        setupMenuBar()
        
        // Start auto-refresh timer (every 30 seconds)
        startAutoRefresh()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        autoRefreshTimer?.invalidate()
    }
    
    func startAutoRefresh() {
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenu()
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "person.2.circle", accessibilityDescription: "TRAE Manager")
            button.image?.isTemplate = true
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Header
        let headerItem = NSMenuItem(title: "🔄 TRAE Manager", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Current profile indicator
        let currentProfile = profileManager.getCurrentProfile()
        let currentItem = NSMenuItem(title: "Current: \(currentProfile)", action: nil, keyEquivalent: "")
        currentItem.isEnabled = false
        menu.addItem(currentItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Profiles list with submenu for each
        let profiles = profileManager.listProfiles()
        
        if profiles.isEmpty {
            let noProfilesItem = NSMenuItem(title: "No profiles saved", action: nil, keyEquivalent: "")
            noProfilesItem.isEnabled = false
            menu.addItem(noProfilesItem)
        } else {
            for profile in profiles {
                let profileItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                
                // Build title with status indicator
                var title = profile.isActive ? "● " : "○ "
                title += profile.name
                if let size = profile.size {
                    title += " (\(size))"
                }
                profileItem.title = title
                
                // Create submenu for profile actions
                let profileSubmenu = NSMenu()
                
                // Switch to this profile
                if !profile.isActive {
                    let switchItem = NSMenuItem(title: "Switch to this profile", action: #selector(switchToProfile(_:)), keyEquivalent: "")
                    switchItem.target = self
                    switchItem.representedObject = profile.name
                    profileSubmenu.addItem(switchItem)
                    profileSubmenu.addItem(NSMenuItem.separator())
                }
                
                // Rename
                let renameItem = NSMenuItem(title: "Rename...", action: #selector(renameProfile(_:)), keyEquivalent: "")
                renameItem.target = self
                renameItem.representedObject = profile.name
                profileSubmenu.addItem(renameItem)
                
                // Duplicate
                let duplicateItem = NSMenuItem(title: "Duplicate...", action: #selector(duplicateProfile(_:)), keyEquivalent: "")
                duplicateItem.target = self
                duplicateItem.representedObject = profile.name
                profileSubmenu.addItem(duplicateItem)
                
                // Delete (only if not active)
                if !profile.isActive {
                    profileSubmenu.addItem(NSMenuItem.separator())
                    let deleteItem = NSMenuItem(title: "Delete", action: #selector(deleteProfile(_:)), keyEquivalent: "")
                    deleteItem.target = self
                    deleteItem.representedObject = profile.name
                    profileSubmenu.addItem(deleteItem)
                }
                
                // Show chat count if available
                if let chatCount = profileManager.getChatCount(for: profile.path) {
                    profileSubmenu.addItem(NSMenuItem.separator())
                    let chatItem = NSMenuItem(title: "💬 \(chatCount) chat sessions", action: nil, keyEquivalent: "")
                    chatItem.isEnabled = false
                    profileSubmenu.addItem(chatItem)
                }
                
                profileItem.submenu = profileSubmenu
                menu.addItem(profileItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick actions
        let saveItem = NSMenuItem(title: "💾 Save Current Session...", action: #selector(saveCurrentSession), keyEquivalent: "s")
        saveItem.target = self
        menu.addItem(saveItem)
        
        let createItem = NSMenuItem(title: "➕ Create Empty Profile...", action: #selector(createNewProfile), keyEquivalent: "n")
        createItem.target = self
        menu.addItem(createItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // TRAE status
        let traeRunning = profileManager.isTraeRunning()
        let traeStatusItem = NSMenuItem(
            title: traeRunning ? "🟢 TRAE: Running" : "⚪ TRAE: Not Running",
            action: nil,
            keyEquivalent: ""
        )
        traeStatusItem.isEnabled = false
        menu.addItem(traeStatusItem)
        
        // Open TRAE
        if !traeRunning {
            let openItem = NSMenuItem(title: "▶️ Open TRAE", action: #selector(openTrae), keyEquivalent: "o")
            openItem.target = self
            menu.addItem(openItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings submenu
        let settingsItem = NSMenuItem(title: "⚙️ Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()
        
        // Launch at login
        let launchAtLogin = isLaunchAtLoginEnabled()
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLogin ? .on : .off
        settingsSubmenu.addItem(launchItem)
        
        // Open profiles folder
        let openFolderItem = NSMenuItem(title: "Open Profiles Folder", action: #selector(openProfilesFolder), keyEquivalent: "")
        openFolderItem.target = self
        settingsSubmenu.addItem(openFolderItem)
        
        // Backup all profiles
        let backupItem = NSMenuItem(title: "Backup All Profiles...", action: #selector(backupAllProfiles), keyEquivalent: "")
        backupItem.target = self
        settingsSubmenu.addItem(backupItem)
        
        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Refresh
        let refreshItem = NSMenuItem(title: "🔄 Refresh", action: #selector(refreshMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit TRAE Manager", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    // MARK: - Profile Actions
    
    @objc func switchToProfile(_ sender: NSMenuItem) {
        guard let profileName = sender.representedObject as? String else { return }
        
        let alert = NSAlert()
        alert.messageText = "Switch Profile"
        alert.informativeText = "Switch to profile '\(profileName)'?\n\nThis will restart TRAE."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Switch")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                await profileManager.switchProfile(to: profileName)
                await MainActor.run {
                    updateMenu()
                    showNotification(title: "Profile Switched", body: "Now using: \(profileName)")
                }
            }
        }
    }
    
    @objc func renameProfile(_ sender: NSMenuItem) {
        guard let oldName = sender.representedObject as? String else { return }
        
        let alert = NSAlert()
        alert.messageText = "Rename Profile"
        alert.informativeText = "Enter new name for '\(oldName)':"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = oldName
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty && newName != oldName {
                let success = profileManager.renameProfile(from: oldName, to: newName)
                if success {
                    updateMenu()
                    showNotification(title: "Profile Renamed", body: "\(oldName) → \(newName)")
                } else {
                    showErrorAlert(message: "Failed to rename profile. Name may already exist or be invalid.")
                }
            }
        }
    }
    
    @objc func duplicateProfile(_ sender: NSMenuItem) {
        guard let sourceName = sender.representedObject as? String else { return }
        
        let alert = NSAlert()
        alert.messageText = "Duplicate Profile"
        alert.informativeText = "Enter name for the copy of '\(sourceName)':"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Duplicate")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "\(sourceName)_copy"
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newName.isEmpty {
                Task {
                    let success = await profileManager.duplicateProfile(from: sourceName, to: newName)
                    await MainActor.run {
                        if success {
                            updateMenu()
                            showNotification(title: "Profile Duplicated", body: "Created: \(newName)")
                        } else {
                            showErrorAlert(message: "Failed to duplicate profile")
                        }
                    }
                }
            }
        }
    }
    
    @objc func deleteProfile(_ sender: NSMenuItem) {
        guard let profileName = sender.representedObject as? String else { return }
        
        let alert = NSAlert()
        alert.messageText = "Delete Profile"
        alert.informativeText = "Are you sure you want to delete '\(profileName)'?\n\nThis action cannot be undone."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let success = profileManager.deleteProfile(name: profileName)
            if success {
                updateMenu()
                showNotification(title: "Profile Deleted", body: "Deleted: \(profileName)")
            } else {
                showErrorAlert(message: "Failed to delete profile")
            }
        }
    }
    
    @objc func saveCurrentSession() {
        let alert = NSAlert()
        alert.messageText = "Save Current Session"
        alert.informativeText = "Enter a name for this profile:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "my_account"
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                Task {
                    let success = await profileManager.saveProfile(name: name)
                    await MainActor.run {
                        if success {
                            updateMenu()
                            showNotification(title: "Profile Saved", body: "Saved as: \(name)")
                        } else {
                            showErrorAlert(message: "Failed to save profile")
                        }
                    }
                }
            }
        }
    }
    
    @objc func createNewProfile() {
        let alert = NSAlert()
        alert.messageText = "Create Empty Profile"
        alert.informativeText = "Enter a name for the new profile:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "new_account"
        alert.accessoryView = textField
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                let success = profileManager.createProfile(name: name)
                if success {
                    updateMenu()
                    showNotification(title: "Profile Created", body: "Created: \(name)")
                } else {
                    showErrorAlert(message: "Failed to create profile. Name may already exist or be invalid.")
                }
            }
        }
    }
    
    // MARK: - TRAE Control
    
    @objc func openTrae() {
        profileManager.openTrae()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.updateMenu()
        }
    }
    
    // MARK: - Settings Actions
    
    @objc func toggleLaunchAtLogin() {
        let currentState = isLaunchAtLoginEnabled()
        setLaunchAtLogin(!currentState)
        updateMenu()
    }
    
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }
    
    @objc func openProfilesFolder() {
        NSWorkspace.shared.open(profileManager.profilesDir)
    }
    
    @objc func backupAllProfiles() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.folder]
        panel.nameFieldStringValue = "TRAE-Profiles-Backup"
        panel.canCreateDirectories = true
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                let success = await profileManager.backupAllProfiles(to: url)
                await MainActor.run {
                    if success {
                        showNotification(title: "Backup Complete", body: "Profiles backed up to: \(url.lastPathComponent)")
                        NSWorkspace.shared.open(url)
                    } else {
                        showErrorAlert(message: "Failed to backup profiles")
                    }
                }
            }
        }
    }
    
    // MARK: - Utility
    
    @objc func refreshMenu() {
        updateMenu()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
