import SwiftUI
import UserNotifications

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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize profile manager
        profileManager = ProfileManager()
        
        // Setup menu bar
        setupMenuBar()
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
        
        // Profiles submenu
        let profilesItem = NSMenuItem(title: "Switch Profile", action: nil, keyEquivalent: "")
        let profilesSubmenu = NSMenu()
        
        let profiles = profileManager.listProfiles()
        
        if profiles.isEmpty {
            let noProfilesItem = NSMenuItem(title: "No profiles saved", action: nil, keyEquivalent: "")
            noProfilesItem.isEnabled = false
            profilesSubmenu.addItem(noProfilesItem)
        } else {
            for profile in profiles {
                let profileItem = NSMenuItem(
                    title: profile.name,
                    action: #selector(switchToProfile(_:)),
                    keyEquivalent: ""
                )
                profileItem.target = self
                profileItem.representedObject = profile.name
                
                if profile.isActive {
                    profileItem.state = .on
                }
                
                // Add size info
                if let size = profile.size {
                    profileItem.title = "\(profile.name) (\(size))"
                }
                
                profilesSubmenu.addItem(profileItem)
            }
        }
        
        profilesItem.submenu = profilesSubmenu
        menu.addItem(profilesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Save current session
        let saveItem = NSMenuItem(title: "Save Current Session...", action: #selector(saveCurrentSession), keyEquivalent: "s")
        saveItem.target = self
        menu.addItem(saveItem)
        
        // Create new profile
        let createItem = NSMenuItem(title: "Create Empty Profile...", action: #selector(createNewProfile), keyEquivalent: "n")
        createItem.target = self
        menu.addItem(createItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // TRAE status
        let traeRunning = profileManager.isTraeRunning()
        let traeStatusItem = NSMenuItem(
            title: traeRunning ? "TRAE: Running" : "TRAE: Not Running",
            action: nil,
            keyEquivalent: ""
        )
        traeStatusItem.isEnabled = false
        menu.addItem(traeStatusItem)
        
        // Open TRAE
        if !traeRunning {
            let openItem = NSMenuItem(title: "Open TRAE", action: #selector(openTrae), keyEquivalent: "o")
            openItem.target = self
            menu.addItem(openItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Refresh
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshMenu), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit TRAE Manager", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
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
                    showErrorAlert(message: "Failed to create profile")
                }
            }
        }
    }
    
    @objc func openTrae() {
        profileManager.openTrae()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.updateMenu()
        }
    }
    
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
