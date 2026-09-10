//
//  InspectionListView.swift
//  Sertifisering
//
//  Created by Terje Moe on 03/09/2026.
//

import SwiftUI
import SwiftData

struct InspectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]
    @AppStorage("app.user.role") private var userRoleRawValue = AppUserRole.technician.rawValue
    @AppStorage("cloudkit.company.lastSyncStatus") private var lastCloudKitSyncStatus = ""
    @State private var isShowingSettings = false
    @State private var selectedFilter: InspectionListFilter = .all
    @State private var hasAppliedRoleDefaultFilter = false
    @State private var hasAttemptedAutomaticDownload = false
    @State private var isUploadingCompanyData = false
    @State private var isDownloadingCompanyData = false
    @State private var cloudKitSyncMessage: String?
    @State private var searchText = ""
    @State private var billingExportURL: URL?
    @State private var billingExportMessage: String?

    private var filteredInspections: [Inspection] {
        inspections.filter { inspection in
            selectedFilter.includes(inspection) && matchesSearch(inspection)
        }
    }

    private var currentRole: AppUserRole {
        AppUserRole(rawValue: userRoleRawValue) ?? .technician
    }

    private var showsOfficeSummary: Bool {
        currentRole == .office || currentRole == .admin
    }

    private var canCreateInspection: Bool {
        currentRole == .technician || currentRole == .admin
    }

    private var draftCount: Int {
        inspections.filter { InspectionListFilter.draft.includes($0) }.count
    }

    private var completedByTechnicianCount: Int {
        inspections.filter { $0.workflowStatus == .completedByTechnician }.count
    }

    private var readyForOfficeCount: Int {
        inspections.filter(\.isReadyForOfficeQueue).count
    }

    private var processedCount: Int {
        inspections.filter { $0.workflowStatus == .processedByOffice }.count
    }

    private var notInvoicedCount: Int {
        inspections.filter(\.isBillingQueue).count
    }

    private var invoicedCount: Int {
        inspections.filter(\.isInvoicedQueue).count
    }

    var body: some View {
        NavigationStack {
            List {
                if let cloudKitSyncMessage {
                    Section("iCloud") {
                        Text(cloudKitSyncMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if !lastCloudKitSyncStatus.isEmpty {
                    Section("iCloud") {
                        Text(lastCloudKitSyncStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !inspections.isEmpty && !showsOfficeSummary {
                    Section("Tekniker") {
                        Button {
                            selectedFilter = .draft
                        } label: {
                            OfficeSummaryRow(
                                title: "Utkast",
                                value: draftCount,
                                systemImage: "square.and.pencil"
                            )
                        }

                        Button {
                            selectedFilter = .readyForOffice
                        } label: {
                            OfficeSummaryRow(
                                title: "Ferdig fra tekniker",
                                value: completedByTechnicianCount,
                                systemImage: "checkmark.seal"
                            )
                        }
                    }
                }

                if !inspections.isEmpty && showsOfficeSummary {
                    Section("Kontor") {
                        Button {
                            selectedFilter = .readyForOffice
                        } label: {
                            OfficeSummaryRow(
                                title: "Klar for behandling",
                                value: readyForOfficeCount,
                                systemImage: "tray.full"
                            )
                        }

                        Button {
                            selectedFilter = .processedByOffice
                        } label: {
                            OfficeSummaryRow(
                                title: "Behandlet",
                                value: processedCount,
                                systemImage: "checkmark.seal"
                            )
                        }

                        Button {
                            selectedFilter = .notInvoiced
                        } label: {
                            OfficeSummaryRow(
                                title: "Ikke fakturert",
                                value: notInvoicedCount,
                                systemImage: "doc.plaintext"
                            )
                        }

                        Button {
                            selectedFilter = .invoiced
                        } label: {
                            OfficeSummaryRow(
                                title: "Fakturert",
                                value: invoicedCount,
                                systemImage: "checkmark.circle"
                            )
                        }

                        Button("Lag fakturagrunnlag", systemImage: "tablecells") {
                            exportBillingCSV()
                        }
                        .disabled(notInvoicedCount == 0)

                        if let billingExportURL {
                            ShareLink(item: billingExportURL) {
                                Label("Del fakturagrunnlag", systemImage: "square.and.arrow.up")
                            }
                        }

                        if let billingExportMessage {
                            Text(billingExportMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if inspections.isEmpty {
                    ContentUnavailableView(
                        showsOfficeSummary ? "Ingen kontroller hentet" : "Ingen kontroller ennå",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(
                            showsOfficeSummary
                            ? "Hent delte firmadata fra iCloud for å se kontroller klare til behandling."
                            : "Opprett første kontroll og registrer maskiner direkte hos kunde."
                        )
                    )
                } else if filteredInspections.isEmpty {
                    ContentUnavailableView(
                        "Ingen kontroller i dette filteret",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Velg et annet filter for å se flere kontroller.")
                    )
                } else {
                    ForEach(filteredInspections) { inspection in
                        NavigationLink {
                            InspectionDetailView(inspection: inspection)
                        } label: {
                            InspectionRow(inspection: inspection)
                        }
                    }
                    .onDelete(perform: deleteInspection)
                }
            }
            .navigationTitle("Sertifisering")
            .searchable(text: $searchText, prompt: "Søk kunde, sted, prosjekt eller maskin")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Innstillinger", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Hent delte firmadata", systemImage: "icloud.and.arrow.down") {
                            downloadSharedCompanyData()
                        }
                        .disabled(!PersistenceController.isCloudKitPrepared || isDownloadingCompanyData)

                        Button("Synk firmadata til deling", systemImage: "icloud.and.arrow.up") {
                            uploadCompanyData()
                        }
                        .disabled(!PersistenceController.isCloudKitPrepared || inspections.isEmpty || isUploadingCompanyData)
                    } label: {
                        Label("iCloud", systemImage: "icloud")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(InspectionListFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        Label(selectedFilter.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if canCreateInspection {
                        Button("Ny kontroll", systemImage: "plus", action: addInspection)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .onAppear {
                applyRoleDefaultFilterIfNeeded()
                downloadAutomaticallyForOfficeIfNeeded()
            }
            .refreshable {
                await downloadSharedCompanyData()
            }
        }
    }

    private func addInspection() {
        let inspection = Inspection()
        modelContext.insert(inspection)
    }

    private func deleteInspection(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredInspections[index])
        }
    }

    private func applyRoleDefaultFilterIfNeeded() {
        guard !hasAppliedRoleDefaultFilter else {
            return
        }

        if showsOfficeSummary {
            selectedFilter = .readyForOffice
        }
        hasAppliedRoleDefaultFilter = true
    }

    private func downloadAutomaticallyForOfficeIfNeeded() {
        guard showsOfficeSummary, !hasAttemptedAutomaticDownload, PersistenceController.isCloudKitPrepared else {
            return
        }

        hasAttemptedAutomaticDownload = true
        Task {
            await downloadSharedCompanyData()
        }
    }

    private func uploadCompanyData() {
        isUploadingCompanyData = true
        cloudKitSyncMessage = "Sender firmadata til iCloud..."

        CloudKitSharingSupport.uploadCompanyData(inspections: inspections) { result in
            Task { @MainActor in
                isUploadingCompanyData = false

                switch result {
                case .success(let summary):
                    let message = "Synket \(formattedSyncDate()) til \(summary.targetDescription): \(summary.recordCount) poster."
                    cloudKitSyncMessage = message
                    lastCloudKitSyncStatus = message
                case .failure(let error):
                    cloudKitSyncMessage = "Kunne ikke synke firmadata: \(error.localizedDescription)"
                }
            }
        }
    }

    private func downloadSharedCompanyData() async {
        await withCheckedContinuation { continuation in
            downloadSharedCompanyData {
                continuation.resume()
            }
        }
    }

    private func downloadSharedCompanyData(completion: (() -> Void)? = nil) {
        isDownloadingCompanyData = true
        cloudKitSyncMessage = "Henter delte firmadata..."

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
                        let message = "Hentet \(formattedSyncDate()) fra \(data.sourceDescription): \(importedCount) nye, \(updatedCount) oppdaterte og \(skippedLocalNewerCount) beholdt lokalt."
                        cloudKitSyncMessage = message
                        lastCloudKitSyncStatus = message
                    } catch {
                        cloudKitSyncMessage = "Kunne ikke lagre delte firmadata lokalt: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    cloudKitSyncMessage = "Kunne ikke hente delte firmadata: \(error.localizedDescription)"
                }

                completion?()
            }
        }
    }

    private func formattedSyncDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: .now)
    }

    private func exportBillingCSV() {
        let billingInspections = inspections
            .filter(\.isBillingQueue)
            .sorted { $0.updatedAt > $1.updatedAt }

        guard !billingInspections.isEmpty else {
            billingExportMessage = "Ingen behandlede kontroller klare for fakturering."
            billingExportURL = nil
            return
        }

        do {
            billingExportURL = try BillingCSVExporter.export(inspections: billingInspections)
            billingExportMessage = "Fakturagrunnlag laget for \(billingInspections.count) kontroller."
        } catch {
            billingExportMessage = "Kunne ikke lage fakturagrunnlag: \(error.localizedDescription)"
            billingExportURL = nil
        }
    }

    private func matchesSearch(_ inspection: Inspection) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return true
        }

        let searchableValues = [
            inspection.companyOwner,
            inspection.contactPerson,
            inspection.address,
            inspection.location,
            inspection.projectNumber,
            inspection.certificateNumber,
            inspection.inspector,
            inspection.status.rawValue,
            inspection.workflowStatus.rawValue
        ] + (inspection.machines ?? []).flatMap { machine in
            [
                machine.name,
                machine.machineType,
                machine.serialNumber,
                machine.manufacturer,
                machine.craneNumber,
                machine.hoistNumber,
                machine.internalLocation,
                machine.certificateNumber
            ]
        }

        return searchableValues.contains { value in
            value.localizedCaseInsensitiveContains(query)
        }
    }
}

private enum InspectionListFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case draft = "Utkast"
    case readyForOffice = "Klar for kontor"
    case processedByOffice = "Behandlet"
    case notInvoiced = "Ikke fakturert"
    case invoiced = "Fakturert"

    var id: String { rawValue }

    func includes(_ inspection: Inspection) -> Bool {
        switch self {
        case .all:
            true
        case .draft:
            inspection.workflowStatus == .draft
        case .readyForOffice:
            inspection.isReadyForOfficeQueue
        case .processedByOffice:
            inspection.workflowStatus == .processedByOffice
        case .notInvoiced:
            inspection.isBillingQueue
        case .invoiced:
            inspection.isInvoicedQueue
        }
    }
}

private struct OfficeSummaryRow: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value.formatted())
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .foregroundStyle(.primary)
    }
}

private struct InspectionRow: View {
    let inspection: Inspection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(inspection.companyOwner.isEmpty ? "Ny kontroll" : inspection.companyOwner)
                .font(.headline)
            Text(inspection.location.isEmpty ? "Ingen lokasjon" : inspection.location)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom) {
                Label("\((inspection.machines ?? []).count) maskiner", systemImage: "wrench.and.screwdriver")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(inspection.workflowStatus.rawValue)
                    Text(inspection.status.rawValue)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if inspection.checklistRemarkCount > 0 {
                Label("\(inspection.checklistRemarkCount) mangler", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if inspection.isReadyForOfficeQueue && !inspection.hasOfficeProcessingData {
                Label("Mangler sertifikatnummer", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InspectionListView()
        .modelContainer(for: [Inspection.self, Machine.self, MachineChecklistItem.self], inMemory: true)
}
