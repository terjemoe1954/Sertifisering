import Foundation
import SwiftData

enum PersistenceController {
    static let databaseFileName = "Sertifisering.store"
    static let cloudKitDatabaseFileName = "SertifiseringCloud.store"
    static let backupDirectoryName = "MigrationBackups"
    static let migrationMetadataKey = "persistence.migration.metadata"
    static let pendingRestoreBackupNameKey = "persistence.pending_restore_backup_name"
    static let cloudKitEnabledDefaultsKey = "persistence.cloudkit.enabled"
    static let cloudKitContainerDefaultsKey = "persistence.cloudkit.container"
    static let defaultCloudKitContainerIdentifier = "iCloud.com.terjemoe.Sertifisering"
    static let onlineGuideURLString = "https://example.com/sertifisering/brukerveiledning"

    enum StorageMode: Equatable {
        case localOnly
        case cloudKitPrivate(containerIdentifier: String)
    }

    struct MigrationMetadata: Codable {
        let createdAt: Date
        let sourceDatabasePath: String
        let appVersion: String
        let buildNumber: String
        let storageMode: String
    }

    struct BackupSnapshot: Identifiable, Equatable {
        let name: String
        let createdAt: Date
        let directoryURL: URL

        var id: String { name }
    }

    static var currentStorageMode: StorageMode {
        resolveStorageMode()
    }

    static func makeModelContainer(
        storageMode: StorageMode = currentStorageMode,
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema([
            Inspection.self,
            Machine.self,
            MachineChecklistItem.self
        ])

        let configuration: ModelConfiguration
        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(
                "InMemoryStore",
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true,
                groupContainer: .automatic,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                configurationName(for: storageMode),
                schema: schema,
                url: databaseURL(for: storageMode),
                allowsSave: true,
                cloudKitDatabase: cloudKitDatabase(for: storageMode)
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func registerMigrationBaselineIfNeeded() {
        guard migrationMetadata == nil else { return }

        let metadata = MigrationMetadata(
            createdAt: .now,
            sourceDatabasePath: databaseURL.path,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Ukjent",
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Ukjent",
            storageMode: storageModeDescription(currentStorageMode)
        )

        if let encoded = try? JSONEncoder().encode(metadata) {
            UserDefaults.standard.set(encoded, forKey: migrationMetadataKey)
        }
    }

    static func createMigrationBackupIfNeeded() throws -> URL? {
        let sourceFiles = existingStoreFiles()
        guard !sourceFiles.isEmpty else { return nil }

        let backupDirectory = try makeBackupDirectory()
        let timestamp = backupTimestampString(from: .now)
        let snapshotDirectory = backupDirectory.appendingPathComponent("store-\(timestamp)", isDirectory: true)
        try FileManager.default.createDirectory(at: snapshotDirectory, withIntermediateDirectories: true)

        for sourceURL in sourceFiles {
            let targetURL = snapshotDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        }

        return snapshotDirectory
    }

    static func availableBackups() -> [BackupSnapshot] {
        guard let backupDirectory = try? makeBackupDirectory(),
              let directoryContents = try? FileManager.default.contentsOfDirectory(
                at: backupDirectory,
                includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
              ) else {
            return []
        }

        return directoryContents.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey])
            guard values?.isDirectory == true else { return nil }
            return BackupSnapshot(
                name: url.lastPathComponent,
                createdAt: values?.creationDate ?? .distantPast,
                directoryURL: url
            )
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    static func queueRestore(from backup: BackupSnapshot) {
        UserDefaults.standard.set(backup.name, forKey: pendingRestoreBackupNameKey)
    }

    static func clearQueuedRestore() {
        UserDefaults.standard.removeObject(forKey: pendingRestoreBackupNameKey)
    }

    static var queuedRestoreBackupName: String? {
        UserDefaults.standard.string(forKey: pendingRestoreBackupNameKey)
    }

    static func applyPendingRestoreIfNeeded() throws -> Bool {
        guard let backupName = queuedRestoreBackupName else {
            return false
        }

        let backupURL = try makeBackupDirectory().appendingPathComponent(backupName, isDirectory: true)
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            clearQueuedRestore()
            return false
        }

        try replaceStoreFiles(withContentsOf: backupURL)
        clearQueuedRestore()
        return true
    }

    static var migrationMetadata: MigrationMetadata? {
        guard let data = UserDefaults.standard.data(forKey: migrationMetadataKey) else {
            return nil
        }
        return try? JSONDecoder().decode(MigrationMetadata.self, from: data)
    }

    static var databaseURL: URL {
        databaseURL(fileName: databaseFileName)
    }

    static var cloudKitDatabaseURL: URL {
        databaseURL(fileName: cloudKitDatabaseFileName)
    }

    static var databaseDisplayPath: String {
        databaseURL.path
    }

    static var onlineGuideURL: URL? {
        URL(string: onlineGuideURLString)
    }

    static var isCloudKitPrepared: Bool {
        configuredCloudKitContainerIdentifier != nil
    }

    static var isCloudKitEnabledInSettings: Bool {
        UserDefaults.standard.bool(forKey: cloudKitEnabledDefaultsKey)
    }

    static var configuredCloudKitContainerIdentifier: String? {
        let configuredValue = UserDefaults.standard.string(forKey: cloudKitContainerDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let configuredValue, !configuredValue.isEmpty {
            return configuredValue
        }

        if defaultCloudKitContainerIdentifier.contains(".example.") {
            return nil
        }

        return defaultCloudKitContainerIdentifier
    }

    static var migrationStatusText: String {
        let mode = storageModeDescription(currentStorageMode)
        if let metadata = migrationMetadata {
            return "Lagring: \(mode). Migreringsgrunnlag registrert \(formattedDate(metadata.createdAt))."
        }
        return "Lagring: \(mode). Migreringsgrunnlag ikke registrert ennå."
    }

    static var cloudKitStatusText: String {
        if isCloudKitEnabledInSettings {
            if let identifier = configuredCloudKitContainerIdentifier {
                return "iCloud-testmodus er slått på. Appen bruker container \(identifier) etter restart."
            }
            return "iCloud-testmodus er slått på, men container-ID mangler. Appen fortsetter lokalt til dette er satt."
        }

        if let identifier = configuredCloudKitContainerIdentifier {
            return "iCloud-testmodus er avslått. Container-ID er lagret: \(identifier)."
        }

        return "iCloud-testmodus er avslått. Legg inn riktig container-ID før aktivering."
    }

    static var restoreStatusText: String {
        if let queuedRestoreBackupName {
            return "Gjenoppretting er planlagt fra \(queuedRestoreBackupName) ved neste oppstart."
        }
        return "Ingen gjenoppretting er planlagt."
    }

    private static func configurationName(for storageMode: StorageMode) -> String {
        switch storageMode {
        case .localOnly:
            return "LocalStore"
        case .cloudKitPrivate:
            return "CloudKitStore"
        }
    }

    private static func cloudKitDatabase(for storageMode: StorageMode) -> ModelConfiguration.CloudKitDatabase {
        switch storageMode {
        case .localOnly:
            return .none
        case .cloudKitPrivate(let containerIdentifier):
            return .private(containerIdentifier)
        }
    }

    private static func storageModeDescription(_ storageMode: StorageMode) -> String {
        switch storageMode {
        case .localOnly:
            return "Kun lokal database"
        case .cloudKitPrivate(let containerIdentifier):
            return "iCloud privat database (\(containerIdentifier))"
        }
    }

    private static func resolveStorageMode() -> StorageMode {
        let cloudKitEnabled = UserDefaults.standard.bool(forKey: cloudKitEnabledDefaultsKey)

        guard cloudKitEnabled else {
            return .localOnly
        }

        guard let containerIdentifier = configuredCloudKitContainerIdentifier else {
            return .localOnly
        }

        return .cloudKitPrivate(containerIdentifier: containerIdentifier)
    }

    private static func databaseURL(for storageMode: StorageMode) -> URL {
        switch storageMode {
        case .localOnly:
            return databaseURL
        case .cloudKitPrivate:
            return cloudKitDatabaseURL
        }
    }

    private static func databaseURL(fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directory.appendingPathComponent("Sertifisering", isDirectory: true)

        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }

        return appDirectory.appendingPathComponent(fileName)
    }

    private static func existingStoreFiles() -> [URL] {
        let baseURL = databaseURL
        let supportURLs = [
            baseURL,
            baseURL.appendingPathExtension("wal"),
            baseURL.appendingPathExtension("shm"),
            baseURL.deletingLastPathComponent().appendingPathComponent(".\(baseURL.lastPathComponent)_SUPPORT", isDirectory: true),
            baseURL.deletingLastPathComponent().appendingPathComponent("\(baseURL.deletingPathExtension().lastPathComponent)_ckAssets", isDirectory: true)
        ]

        return supportURLs.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func makeBackupDirectory() throws -> URL {
        let backupDirectory = databaseURL
            .deletingLastPathComponent()
            .appendingPathComponent(backupDirectoryName, isDirectory: true)

        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }

        return backupDirectory
    }

    private static func replaceStoreFiles(withContentsOf backupDirectory: URL) throws {
        let fileManager = FileManager.default
        let destinationDirectory = databaseURL.deletingLastPathComponent()
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)

        for existingURL in existingStoreFiles() {
            if fileManager.fileExists(atPath: existingURL.path) {
                try fileManager.removeItem(at: existingURL)
            }
        }

        for sourceURL in backupFiles {
            let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func backupTimestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
}
