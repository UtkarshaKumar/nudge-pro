import Foundation

/// Handles persistence of Session data to disk as JSON files.
/// Sessions are stored in ~/Documents/Nudge Sessions/{uuid}/session.json
final class SessionStore {

    static let shared = SessionStore()

    private var sessionsRoot: URL {
        let path = UserPreferences.shared.storagePath
        let expandedPath = NSString(string: path).expandingTildeInPath
        return URL(fileURLWithPath: expandedPath)
    }

    // MARK: - Save

    func save(_ session: Session) {
        let sessionDir = sessionsRoot.appendingPathComponent(session.id.uuidString)
        do {
            try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(session)
            let fileURL = sessionDir.appendingPathComponent("session.json")
            try data.write(to: fileURL, options: .atomic)
            print("SessionStore: saved \(session.id) to \(fileURL.path)")
        } catch {
            print("SessionStore: failed to save session \(session.id) - \(error)")
        }
    }

    // MARK: - Load

    func loadAll() -> [Session] {
        guard FileManager.default.fileExists(atPath: sessionsRoot.path) else {
            return []
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: sessionsRoot,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            var sessions: [Session] = []
            let decoder = JSONDecoder()

            for dir in contents where dir.hasDirectoryPath {
                let jsonFile = dir.appendingPathComponent("session.json")
                guard FileManager.default.fileExists(atPath: jsonFile.path) else { continue }
                do {
                    let data = try Data(contentsOf: jsonFile)
                    let session = try decoder.decode(Session.self, from: data)
                    sessions.append(session)
                } catch {
                    print("SessionStore: failed to decode \(jsonFile.path) - \(error)")
                }
            }

            return sessions.sorted { $0.startedAt > $1.startedAt }
        } catch {
            print("SessionStore: failed to list sessions - \(error)")
            return []
        }
    }

    // MARK: - Delete

    func delete(_ session: Session) {
        let sessionDir = sessionsRoot.appendingPathComponent(session.id.uuidString)
        do {
            try FileManager.default.removeItem(at: sessionDir)
            print("SessionStore: deleted \(session.id)")
        } catch {
            print("SessionStore: failed to delete \(session.id) - \(error)")
        }
    }
    
    // MARK: - Cleanup Old Sessions

    func cleanupOldSessions() {
        let retentionDays = UserPreferences.shared.cleanupRetentionDays
        
        guard retentionDays > 0 else {
            print("SessionStore: cleanup disabled (retention = 0)")
            return
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
        
        guard FileManager.default.fileExists(atPath: sessionsRoot.path) else {
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: sessionsRoot,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            var deletedCount = 0
            
            for dir in contents where dir.hasDirectoryPath {
                let jsonFile = dir.appendingPathComponent("session.json")
                guard FileManager.default.fileExists(atPath: jsonFile.path) else { continue }
                
                do {
                    let data = try Data(contentsOf: jsonFile)
                    let session = try JSONDecoder().decode(Session.self, from: data)
                    
                    if session.startedAt < cutoffDate {
                        try FileManager.default.removeItem(at: dir)
                        deletedCount += 1
                        print("SessionStore: deleted old session \(session.id) from \(session.formattedDate)")
                    }
                } catch {
                    print("SessionStore: failed to process \(jsonFile.path) - \(error)")
                }
            }
            
            if deletedCount > 0 {
                print("SessionStore: cleanup complete - deleted \(deletedCount) old sessions")
            } else {
                print("SessionStore: no old sessions to delete")
            }
            
        } catch {
            print("SessionStore: cleanup failed - \(error)")
        }
    }
}
