import Foundation

struct Profile {
    let name: String
    let path: URL
    var isActive: Bool
    var size: String?
}

class ProfileManager {
    let traePath: URL
    let managerRoot: URL
    let profilesDir: URL
    let currentFile: URL
    
    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        traePath = home.appendingPathComponent("Library/Application Support/Trae")
        managerRoot = home.appendingPathComponent(".trae-manager")
        profilesDir = managerRoot.appendingPathComponent("profiles")
        currentFile = managerRoot.appendingPathComponent("current_profile")
        
        // Ensure directories exist
        try? FileManager.default.createDirectory(at: profilesDir, withIntermediateDirectories: true)
    }
    
    // MARK: - Profile Operations
    
    func listProfiles() -> [Profile] {
        var profiles: [Profile] = []
        let currentProfile = getCurrentProfile()
        
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: profilesDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            return profiles
        }
        
        for url in contents {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                let name = url.lastPathComponent
                let size = getDirectorySize(url)
                let isActive = name == currentProfile
                profiles.append(Profile(name: name, path: url, isActive: isActive, size: size))
            }
        }
        
        return profiles.sorted { $0.name < $1.name }
    }
    
    func getCurrentProfile() -> String {
        // Check if TRAE path is a symlink
        var isSymlink = false
        if let attrs = try? FileManager.default.attributesOfItem(atPath: traePath.path),
           let type = attrs[.type] as? FileAttributeType,
           type == .typeSymbolicLink {
            isSymlink = true
        }
        
        if isSymlink {
            if let target = try? FileManager.default.destinationOfSymbolicLink(atPath: traePath.path) {
                return URL(fileURLWithPath: target).lastPathComponent
            }
        }
        
        // Not managed by symlink
        if FileManager.default.fileExists(atPath: traePath.path) {
            return "(original)"
        }
        
        return "(none)"
    }
    
    func createProfile(name: String) -> Bool {
        guard isValidProfileName(name) else { return false }
        
        let profilePath = profilesDir.appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: profilePath.path) {
            return false
        }
        
        do {
            try FileManager.default.createDirectory(at: profilePath, withIntermediateDirectories: true)
            return true
        } catch {
            print("Failed to create profile: \(error)")
            return false
        }
    }
    
    func saveProfile(name: String) async -> Bool {
        guard isValidProfileName(name) else { return false }
        
        let profilePath = profilesDir.appendingPathComponent(name)
        
        // Remove existing if present
        if FileManager.default.fileExists(atPath: profilePath.path) {
            try? FileManager.default.removeItem(at: profilePath)
        }
        
        // Get source path (either symlink target or original)
        var sourcePath = traePath
        if let attrs = try? FileManager.default.attributesOfItem(atPath: traePath.path),
           let type = attrs[.type] as? FileAttributeType,
           type == .typeSymbolicLink,
           let target = try? FileManager.default.destinationOfSymbolicLink(atPath: traePath.path) {
            sourcePath = URL(fileURLWithPath: target)
        }
        
        guard FileManager.default.fileExists(atPath: sourcePath.path) else {
            return false
        }
        
        do {
            try FileManager.default.copyItem(at: sourcePath, to: profilePath)
            return true
        } catch {
            print("Failed to save profile: \(error)")
            return false
        }
    }
    
    func switchProfile(to name: String) async {
        let profilePath = profilesDir.appendingPathComponent(name)
        
        guard FileManager.default.fileExists(atPath: profilePath.path) else {
            return
        }
        
        // Stop TRAE
        await stopTrae()
        
        // Handle current data
        var isSymlink = false
        if let attrs = try? FileManager.default.attributesOfItem(atPath: traePath.path),
           let type = attrs[.type] as? FileAttributeType,
           type == .typeSymbolicLink {
            isSymlink = true
        }
        
        if FileManager.default.fileExists(atPath: traePath.path) && !isSymlink {
            // First time: backup original
            let defaultProfile = profilesDir.appendingPathComponent("default")
            if !FileManager.default.fileExists(atPath: defaultProfile.path) {
                try? FileManager.default.moveItem(at: traePath, to: defaultProfile)
            } else {
                try? FileManager.default.removeItem(at: traePath)
            }
        } else if isSymlink {
            try? FileManager.default.removeItem(at: traePath)
        }
        
        // Create symlink
        do {
            try FileManager.default.createSymbolicLink(at: traePath, withDestinationURL: profilePath)
            try name.write(to: currentFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create symlink: \(error)")
        }
        
        // Start TRAE
        openTrae()
    }
    
    func deleteProfile(name: String) -> Bool {
        let currentProfile = getCurrentProfile()
        if name == currentProfile {
            return false
        }
        
        let profilePath = profilesDir.appendingPathComponent(name)
        
        do {
            try FileManager.default.removeItem(at: profilePath)
            return true
        } catch {
            print("Failed to delete profile: \(error)")
            return false
        }
    }
    
    // MARK: - TRAE Control
    
    func isTraeRunning() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-x", "Trae"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func stopTrae() async {
        guard isTraeRunning() else { return }
        
        let task = Process()
        task.launchPath = "/usr/bin/pkill"
        task.arguments = ["-x", "Trae"]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to stop TRAE: \(error)")
        }
        
        // Wait for process to fully terminate
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Force kill if still running
        if isTraeRunning() {
            let forceTask = Process()
            forceTask.launchPath = "/usr/bin/pkill"
            forceTask.arguments = ["-9", "-x", "Trae"]
            try? forceTask.run()
            forceTask.waitUntilExit()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    
    func openTrae() {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-a", "Trae"]
        
        do {
            try task.run()
        } catch {
            print("Failed to open TRAE: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    func isValidProfileName(_ name: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9_-]+$")
        let range = NSRange(name.startIndex..., in: name)
        return regex?.firstMatch(in: name, range: range) != nil
    }
    
    func getDirectorySize(_ url: URL) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/du"
        task.arguments = ["-sh", url.path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.split(separator: "\t").first.map(String.init)
            }
        } catch {
            print("Failed to get directory size: \(error)")
        }
        
        return nil
    }
}
