import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Lys"
        case .dark:
            return "Mørk"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("app.appearance.mode") private var appearanceModeRawValue = AppAppearance.system.rawValue
    @State private var backups: [PersistenceController.BackupSnapshot] = []
    @State private var backupMessage: String?
    @State private var restoreMessage: String?
    @State private var backupToRestore: PersistenceController.BackupSnapshot?
    @State private var isShowingHelpGuide = false

    private var appearanceMode: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceModeRawValue) ?? .system },
            set: { appearanceModeRawValue = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Utseende") {
                    Picker("Modus", selection: appearanceMode) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Brukerveiledning") {
                    Button("Åpne brukerveiledning", systemImage: "book") {
                        isShowingHelpGuide = true
                    }
                }

                Section("Backup og restore") {
                    Button("Lag ny backup", systemImage: "externaldrive.badge.plus") {
                        createBackup()
                    }

                    if let backupMessage {
                        Text(backupMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(PersistenceController.restoreStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if backups.isEmpty {
                        Text("Ingen backups funnet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(backups) { backup in
                            Button {
                                backupToRestore = backup
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.name)
                                    Text(formattedDate(backup.createdAt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Appinformasjon") {
                    LabeledContent("Versjon", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                }
            }
            .navigationTitle("Innstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lukk") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Planlegg gjenoppretting",
                isPresented: restoreDialogIsPresented,
                titleVisibility: .visible
            ) {
                if let backupToRestore {
                    Button("Gjenopprett fra \(backupToRestore.name)") {
                        queueRestore(from: backupToRestore)
                    }
                }
                Button("Avbryt", role: .cancel) {
                    backupToRestore = nil
                }
            } message: {
                Text("Databasen gjenopprettes fra valgt backup neste gang appen startes.")
            }
            .onAppear(perform: loadBackups)
            .sheet(isPresented: $isShowingHelpGuide) {
                HelpGuideView()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Ukjent"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Ukjent"
    }

    private var restoreDialogIsPresented: Binding<Bool> {
        Binding(
            get: { backupToRestore != nil },
            set: { isPresented in
                if !isPresented {
                    backupToRestore = nil
                }
            }
        )
    }

    private func loadBackups() {
        backups = PersistenceController.availableBackups()
    }

    private func createBackup() {
        do {
            if let backupURL = try PersistenceController.createMigrationBackupIfNeeded() {
                backupMessage = "Backup lagret i \(backupURL.lastPathComponent)."
                restoreMessage = nil
            } else {
                backupMessage = "Ingen databasefiler finnes ennå. Opprett og lagre en kontroll først."
            }
            loadBackups()
        } catch {
            backupMessage = error.localizedDescription
        }
    }

    private func queueRestore(from backup: PersistenceController.BackupSnapshot) {
        PersistenceController.queueRestore(from: backup)
        restoreMessage = "Restore planlagt fra \(backup.name). Lukk og åpne appen på nytt for å fullføre."
        backupToRestore = nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
}
