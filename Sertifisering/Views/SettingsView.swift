import SwiftUI
import SwiftData
import CloudKit

enum AppUserRole: String, CaseIterable, Identifiable {
    case technician
    case office
    case admin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .technician:
            return "Tekniker"
        case .office:
            return "Kontor"
        case .admin:
            return "Admin"
        }
    }
}

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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]
    @AppStorage("app.appearance.mode") private var appearanceModeRawValue = AppAppearance.system.rawValue
    @AppStorage("app.user.role") private var userRoleRawValue = AppUserRole.technician.rawValue
    @AppStorage(PersistenceController.cloudKitEnabledDefaultsKey) private var cloudKitIsEnabled = false
    @AppStorage(PersistenceController.cloudKitContainerDefaultsKey) private var cloudKitContainerIdentifier = ""
    @State private var backups: [PersistenceController.BackupSnapshot] = []
    @State private var backupMessage: String?
    @State private var restoreMessage: String?
    @State private var cloudKitAccountStatusMessage: String?
    @State private var cloudKitUploadMessage: String?
    @State private var cloudKitShareMessage: String?
    @State private var cloudKitDownloadMessage: String?
    @State private var cloudKitDeleteMessage: String?
    @State private var cloudKitShareAcceptanceMessage: String?
    @State private var isUploadingCompanyData = false
    @State private var isPreparingCompanyShare = false
    @State private var isDownloadingCompanyData = false
    @State private var isDeletingPrivateCloudData = false
    @State private var isConfirmingPrivateCloudDelete = false
    @State private var isConfirmingDeleteAllInspections = false
    @State private var deleteAllInspectionsMessage: String?
    @State private var preparedCompanyShare: CKShare?
    @State private var backupToRestore: PersistenceController.BackupSnapshot?
    @State private var isShowingHelpGuide = false
    @State private var isShowingCompanySharing = false

    private var appearanceMode: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceModeRawValue) ?? .system },
            set: { appearanceModeRawValue = $0.rawValue }
        )
    }

    private var userRole: Binding<AppUserRole> {
        Binding(
            get: { currentRole },
            set: { userRoleRawValue = $0.rawValue }
        )
    }

    private var currentRole: AppUserRole {
        AppUserRole(rawValue: userRoleRawValue) ?? .technician
    }

    private var storageModeTitle: String {
        PersistenceController.isCloudKitEnabledInSettings ? "iCloud etter restart" : "Kun lokalt"
    }

    private var readyForOfficeCount: Int {
        inspections.filter(\.isReadyForOfficeQueue).count
    }

    private var billingQueueCount: Int {
        inspections.filter(\.isBillingQueue).count
    }

    private var invoicedCount: Int {
        inspections.filter(\.isInvoicedQueue).count
    }

    private var newestInspectionDate: Date? {
        inspections.map(\.updatedAt).max()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Brukerrolle") {
                    Picker("Rolle", selection: userRole) {
                        ForEach(AppUserRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Driftsstatus") {
                    LabeledContent("Rolle", value: currentRole.title)
                    LabeledContent("Lagring", value: storageModeTitle)
                    LabeledContent("Kontroller totalt", value: inspections.count.formatted())
                    LabeledContent("Klar for kontor", value: readyForOfficeCount.formatted())
                    LabeledContent("Ikke fakturert", value: billingQueueCount.formatted())
                    LabeledContent("Fakturert", value: invoicedCount.formatted())

                    if let newestInspectionDate {
                        LabeledContent("Sist endret", value: formattedDate(newestInspectionDate))
                    }
                }

                Section("iCloud testmodus") {
                    Toggle("Bruk iCloud/CloudKit", isOn: $cloudKitIsEnabled)

                    TextField("Container-ID", text: $cloudKitContainerIdentifier)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text(PersistenceController.cloudKitStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(PersistenceController.migrationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Sjekk iCloud-konto", systemImage: "icloud") {
                        checkCloudKitAccountStatus()
                    }

                    if let cloudKitAccountStatusMessage {
                        Text(cloudKitAccountStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Synk firmadata til deling", systemImage: "icloud.and.arrow.up") {
                        uploadCompanyData()
                    }
                    .disabled(!PersistenceController.isCloudKitPrepared || inspections.isEmpty || isUploadingCompanyData)

                    if let cloudKitUploadMessage {
                        Text(cloudKitUploadMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Del firmadata med kontor", systemImage: "person.2.badge.plus") {
                        prepareCompanySharing()
                    }
                    .disabled(!PersistenceController.isCloudKitPrepared || isPreparingCompanyShare)

                    if let cloudKitShareMessage {
                        Text(cloudKitShareMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Hent delte firmadata", systemImage: "icloud.and.arrow.down") {
                        downloadSharedCompanyData()
                    }
                    .disabled(!PersistenceController.isCloudKitPrepared || isDownloadingCompanyData)

                    if let cloudKitShareAcceptanceMessage {
                        Text(cloudKitShareAcceptanceMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let cloudKitDownloadMessage {
                        Text(cloudKitDownloadMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Slett private iCloud-testdata", systemImage: "trash", role: .destructive) {
                        isConfirmingPrivateCloudDelete = true
                    }
                    .disabled(!PersistenceController.isCloudKitPrepared || isDeletingPrivateCloudData)

                    if let cloudKitDeleteMessage {
                        Text(cloudKitDeleteMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Slett alle kontroller i appen", systemImage: "trash.circle", role: .destructive) {
                        isConfirmingDeleteAllInspections = true
                    }
                    .disabled(inspections.isEmpty)

                    if let deleteAllInspectionsMessage {
                        Text(deleteAllInspectionsMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Deling krever at mottakeren har egen Apple ID med iCloud aktivert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Endringer i lagringsmodus tas i bruk etter at appen er startet på nytt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
                "Slett alle kontroller?",
                isPresented: $isConfirmingDeleteAllInspections,
                titleVisibility: .visible
            ) {
                Button("Slett alle kontroller", role: .destructive) {
                    deleteAllInspections()
                }
                Button("Avbryt", role: .cancel) { }
            } message: {
                Text("Dette sletter alle kontroller i appens aktive lagring. Hvis iCloud-lagring er aktiv, kan slettingen synkes til iCloud for denne Apple ID-en.")
            }
            .confirmationDialog(
                "Slett private iCloud-testdata?",
                isPresented: $isConfirmingPrivateCloudDelete,
                titleVisibility: .visible
            ) {
                Button("Slett private iCloud-testdata", role: .destructive) {
                    deletePrivateCloudData()
                }
                Button("Avbryt", role: .cancel) { }
            } message: {
                Text("Dette sletter firmadata i privat CloudKit-sone for Apple ID-en som er innlogget på denne enheten. Lokale kontroller på enheten slettes ikke automatisk.")
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
            .onAppear {
                loadBackups()
                loadCloudKitShareAcceptanceMessage()
            }
            .sheet(isPresented: $isShowingHelpGuide) {
                HelpGuideView()
            }
            .sheet(isPresented: $isShowingCompanySharing) {
                if let preparedCompanyShare {
                    CompanyCloudSharingView(share: preparedCompanyShare)
                }
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

    private func loadCloudKitShareAcceptanceMessage() {
        cloudKitShareAcceptanceMessage = UserDefaults.standard.string(
            forKey: CloudKitSharingSupport.shareAcceptanceMessageDefaultsKey
        )
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

    private func checkCloudKitAccountStatus() {
        cloudKitAccountStatusMessage = "Sjekker iCloud-konto..."
        Task {
            let message = await CloudKitSharingSupport.accountStatusText()
            await MainActor.run {
                cloudKitAccountStatusMessage = message
            }
        }
    }

    private func uploadCompanyData() {
        isUploadingCompanyData = true
        cloudKitUploadMessage = "Sender firmadata til iCloud..."

        CloudKitSharingSupport.uploadCompanyData(inspections: inspections) { result in
            Task { @MainActor in
                isUploadingCompanyData = false

                switch result {
                case .success(let summary):
                    cloudKitUploadMessage = "Firmadata synket til \(summary.targetDescription) (\(summary.recordCount) poster)."
                case .failure(let error):
                    cloudKitUploadMessage = "Kunne ikke synke firmadata: \(error.localizedDescription)"
                }
            }
        }
    }

    private func prepareCompanySharing() {
        isPreparingCompanyShare = true
        cloudKitShareMessage = "Klargjør deling..."

        CloudKitSharingSupport.prepareCompanyShare { result in
            Task { @MainActor in
                isPreparingCompanyShare = false

                switch result {
                case .success(let share):
                    preparedCompanyShare = share
                    cloudKitShareMessage = nil
                    isShowingCompanySharing = true
                case .failure(let error):
                    cloudKitShareMessage = "Kunne ikke åpne deling: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deleteAllInspections() {
        let count = inspections.count

        for inspection in inspections {
            modelContext.delete(inspection)
        }

        do {
            try modelContext.save()
            deleteAllInspectionsMessage = "Slettet \(count) kontroller fra appens aktive lagring. Hold appen åpen litt hvis iCloud skal synke slettingen."
        } catch {
            deleteAllInspectionsMessage = "Kunne ikke slette kontroller: \(error.localizedDescription)"
        }
    }

    private func deletePrivateCloudData() {
        isDeletingPrivateCloudData = true
        cloudKitDeleteMessage = "Sletter private iCloud-testdata..."

        CloudKitSharingSupport.deletePrivateCompanyData { result in
            Task { @MainActor in
                isDeletingPrivateCloudData = false

                switch result {
                case .success(let message):
                    cloudKitDeleteMessage = "\(message) Slett appen eller lokale kontroller før du henter på nytt hvis du vil starte helt blankt."
                case .failure(let error):
                    cloudKitDeleteMessage = "Kunne ikke slette private iCloud-testdata: \(error.localizedDescription)"
                }
            }
        }
    }

    private func downloadSharedCompanyData() {
        isDownloadingCompanyData = true
        cloudKitDownloadMessage = "Henter delte firmadata..."

        CloudKitSharingSupport.downloadSharedCompanyData { result in
            Task { @MainActor in
                isDownloadingCompanyData = false

                switch result {
                case .success(let data):
                    var importedCount = 0
                    var updatedCount = 0
                    var skippedLocalNewerCount = 0

                    for sharedInspection in data.inspections {
                        if let existingInspection = inspections.first(where: { $0.id == sharedInspection.id }) {
                            if sharedInspection.updatedAt >= existingInspection.updatedAt {
                                modelContext.delete(existingInspection)
                                modelContext.insert(sharedInspection)
                                updatedCount += 1
                            } else {
                                skippedLocalNewerCount += 1
                            }
                        } else {
                            modelContext.insert(sharedInspection)
                            importedCount += 1
                        }
                    }

                    do {
                        try modelContext.save()
                        cloudKitDownloadMessage = "Hentet fra \(data.sourceDescription): \(data.zoneCount) soner og \(data.recordCount) poster. Importerte \(importedCount) nye, oppdaterte \(updatedCount) og beholdt \(skippedLocalNewerCount) lokale kontroller."
                    } catch {
                        cloudKitDownloadMessage = "Kunne ikke lagre delte firmadata lokalt: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    cloudKitDownloadMessage = "Kunne ikke hente delte firmadata: \(error.localizedDescription)"
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: date)
    }
}
