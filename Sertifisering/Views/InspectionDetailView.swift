import SwiftUI
import SwiftData

struct InspectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Inspection.createdAt, order: .reverse) private var inspections: [Inspection]
    @AppStorage("app.user.role") private var userRoleRawValue = AppUserRole.technician.rawValue
    @Bindable var inspection: Inspection
    @State private var exportedPDFURL: URL?
    @State private var certificateBasisURL: URL?
    @State private var exportErrorMessage: String?
    @State private var completionErrorMessage: String?
    @State private var cloudKitSyncMessage: String?
    @State private var isUploadingCompanyData = false

    var body: some View {
        Form {
            Section("Forside") {
                TextField("Sertifikatnummer", text: $inspection.certificateNumber)
                TextField("Firma / Eier", text: $inspection.companyOwner)
                TextField("Kontaktperson", text: $inspection.contactPerson)
                TextField("Telefon", text: $inspection.phone)
                    .keyboardType(.phonePad)
                TextField("Adresse", text: $inspection.address, axis: .vertical)
                TextField("Prosjektnummer", text: $inspection.projectNumber)
                TextField("Sted", text: $inspection.location)
                TextField("Kontroll utført av", text: $inspection.inspector)
                TextField("Antall vedlegg", text: $inspection.attachmentsCount)
                Picker("Kontrollresultat", selection: $inspection.status) {
                    ForEach(InspectionStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Arbeidsflyt") {
                Picker("Arbeidsstatus", selection: $inspection.workflowStatus) {
                    ForEach(InspectionWorkflowStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }

                if canUseTechnicianActions {
                    Button("Marker ferdig fra tekniker", systemImage: "checkmark.seal", action: completeTechnicianInspection)
                        .disabled(!canCompleteTechnicianInspection || inspection.workflowStatus != .draft)
                }

                if canUseOfficeActions {
                    Button("Marker behandlet av kontor", systemImage: "tray.full", action: processOfficeInspection)
                        .disabled(!canProcessOfficeInspection)

                    Button("Marker fakturert", systemImage: "checkmark.circle", action: markInspectionInvoiced)
                        .disabled(!canMarkInspectionInvoiced)

                    if inspection.isReadyForOfficeQueue && !inspection.hasOfficeProcessingData {
                        Text("Legg inn sertifikatnummer før kontrollen markeres som behandlet av kontor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !inspection.missingTechnicianCompletionRequirements.isEmpty && inspection.workflowStatus == .draft {
                    Text("Mangler: \(inspection.missingTechnicianCompletionRequirements.joined(separator: ", ")).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if canResetWorkflow && inspection.workflowStatus != .draft {
                    Button("Tilbakestill til utkast", systemImage: "arrow.uturn.backward", role: .destructive, action: resetToDraft)
                }

                if let completedAt = inspection.completedAt {
                    LabeledContent("Fullført", value: completedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if let processedAt = inspection.processedAt {
                    LabeledContent("Behandlet", value: processedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if let invoicedAt = inspection.invoicedAt {
                    LabeledContent("Fakturert", value: invoicedAt.formatted(date: .abbreviated, time: .shortened))
                }

                Button("Synk endringer til iCloud", systemImage: "icloud.and.arrow.up", action: uploadCompanyData)
                    .disabled(!PersistenceController.isCloudKitPrepared || inspections.isEmpty || isUploadingCompanyData)

                if let cloudKitSyncMessage {
                    Text(cloudKitSyncMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if canUseTechnicianActions {
                Section("Teknikersjekk") {
                    OfficeCheckRow(
                        title: "Firma/eier",
                        isComplete: !inspection.companyOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    OfficeCheckRow(
                        title: "Kontrollør",
                        isComplete: !inspection.inspector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                    OfficeCheckRow(
                        title: "Minst én maskin",
                        isComplete: !(inspection.machines ?? []).isEmpty
                    )
                }
            }

            if canUseOfficeActions {
                Section("Kontorsjekk") {
                    OfficeCheckRow(
                        title: "Ferdig fra tekniker",
                        isComplete: inspection.isReadyForOfficeQueue || inspection.workflowStatus == .processedByOffice || inspection.workflowStatus == .invoiced
                    )
                    OfficeCheckRow(
                        title: "Sertifikatnummer",
                        isComplete: inspection.hasOfficeProcessingData
                    )
                    OfficeCheckRow(
                        title: "PDF kan genereres",
                        isComplete: inspection.canExportPDF
                    )
                    OfficeCheckRow(
                        title: "Sertifikatgrunnlag kan lages",
                        isComplete: inspection.canExportCertificateBasis
                    )
                    OfficeCheckRow(
                        title: inspection.checklistRemarkCount == 0 ? "Ingen mangler registrert" : "\(inspection.checklistRemarkCount) mangler registrert",
                        isComplete: inspection.checklistRemarkCount == 0
                    )
                    OfficeCheckRow(
                        title: "Klar for fakturagrunnlag",
                        isComplete: inspection.isBillingQueue || inspection.isInvoicedQueue
                    )

                    if !inspection.canProcessByOffice {
                        Text("Mangler før kontorbehandling: \(inspection.missingOfficeProcessingRequirements.joined(separator: ", ")).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Maskiner") {
                if (inspection.machines ?? []).isEmpty {
                    Text("Ingen maskiner lagt til")
                        .foregroundStyle(.secondary)
                }

                ForEach(inspection.machines ?? []) { machine in
                    NavigationLink {
                        MachineDetailView(machine: machine)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(machine.name.isEmpty ? "Ny maskin" : machine.name)
                            Text(machine.machineType)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteMachines)

                if canEditTechnicalContent {
                    Button("Legg til maskin", systemImage: "plus", action: addMachine)
                }
            }

            Section("Merknader og signatur") {
                TextField("Merknader / mangler", text: $inspection.overallNotes, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                TextField("Kontrollør signatur (navn)", text: $inspection.signatureInspectorName)
                SignatureEditor(title: "Kontrollør signatur", drawing: $inspection.inspectorSignatureDrawing)
                TextField("Kundens signatur (navn)", text: $inspection.signatureCustomerName)
                SignatureEditor(title: "Kundens signatur", drawing: $inspection.customerSignatureDrawing)
            }

            Section("Eksport") {
                Button("Generer PDF", systemImage: "doc.richtext", action: exportPDF)
                    .disabled(!inspection.canExportPDF)

                if !inspection.canExportPDF {
                    Text("Legg til minst én maskin før PDF genereres.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let exportedPDFURL {
                    ShareLink(
                        item: exportedPDFURL,
                        preview: SharePreview("Sertifiseringsrapport", image: Image(systemName: "doc.richtext"))
                    ) {
                        Label("Del PDF", systemImage: "square.and.arrow.up")
                    }
                }

                Button("Lag sertifikatgrunnlag", systemImage: "doc.text", action: exportCertificateBasis)
                    .disabled(!inspection.canExportCertificateBasis)

                if !inspection.canExportCertificateBasis {
                    Text("Legg inn sertifikatnummer og minst én maskin før sertifikatgrunnlaget lages.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let certificateBasisURL {
                    ShareLink(
                        item: certificateBasisURL,
                        preview: SharePreview("Sertifikatgrunnlag", image: Image(systemName: "doc.text"))
                    ) {
                        Label("Del sertifikatgrunnlag", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle(inspection.companyOwner.isEmpty ? "Ny kontroll" : inspection.companyOwner)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Kunne ikke lage PDF", isPresented: exportAlertIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage ?? "Ukjent feil")
        }
        .alert("Kontrollen kan ikke fullføres", isPresented: completionAlertIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(completionErrorMessage ?? "Ukjent feil")
        }
    }

    private func addMachine() {
        let machine = Machine.makeDefault()
        machine.inspection = inspection
        inspection.machines = (inspection.machines ?? []) + [machine]
        modelContext.insert(machine)
    }

    private func deleteMachines(at offsets: IndexSet) {
        guard canEditTechnicalContent else {
            completionErrorMessage = "Kontorrollen kan ikke slette maskiner fra kontrollen."
            return
        }

        let machines = inspection.machines ?? []
        for index in offsets {
            modelContext.delete(machines[index])
        }
    }

    private func completeTechnicianInspection() {
        guard canCompleteTechnicianInspection else {
            completionErrorMessage = "Kontrollen mangler: \(inspection.missingTechnicianCompletionRequirements.joined(separator: ", "))."
            return
        }

        inspection.workflowStatus = .completedByTechnician
        saveAndSyncWorkflowChange()
    }

    private func processOfficeInspection() {
        guard inspection.canProcessByOffice else {
            completionErrorMessage = "Kontrollen mangler: \(inspection.missingOfficeProcessingRequirements.joined(separator: ", "))."
            return
        }

        inspection.workflowStatus = .processedByOffice
        saveAndSyncWorkflowChange()
    }

    private func markInspectionInvoiced() {
        guard canMarkInspectionInvoiced else {
            completionErrorMessage = "Kontrollen må være behandlet av kontor før den kan markeres som fakturert."
            return
        }

        inspection.workflowStatus = .invoiced
        saveAndSyncWorkflowChange()
    }

    private func resetToDraft() {
        inspection.workflowStatus = .draft
        inspection.completedAt = nil
        inspection.processedAt = nil
        inspection.invoicedAt = nil
        saveAndSyncWorkflowChange()
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            completionErrorMessage = error.localizedDescription
            return false
        }
    }

    private func saveAndSyncWorkflowChange() {
        guard saveChanges() else {
            return
        }

        if PersistenceController.isCloudKitPrepared {
            uploadCompanyData()
        } else {
            cloudKitSyncMessage = "Endring lagret lokalt. iCloud er ikke aktivert."
        }
    }

    private func uploadCompanyData() {
        do {
            try modelContext.save()
        } catch {
            cloudKitSyncMessage = "Kunne ikke lagre før synk: \(error.localizedDescription)"
            return
        }

        isUploadingCompanyData = true
        cloudKitSyncMessage = "Sender endringer til iCloud..."

        CloudKitSharingSupport.uploadCompanyData(inspections: inspections) { result in
            Task { @MainActor in
                isUploadingCompanyData = false

                switch result {
                case .success(let summary):
                    cloudKitSyncMessage = "Synket til \(summary.targetDescription): \(summary.recordCount) poster."
                case .failure(let error):
                    cloudKitSyncMessage = "Kunne ikke synke endringer: \(error.localizedDescription)"
                }
            }
        }
    }

    private var canCompleteTechnicianInspection: Bool {
        inspection.canCompleteByTechnician
    }

    private var currentRole: AppUserRole {
        AppUserRole(rawValue: userRoleRawValue) ?? .technician
    }

    private var canEditTechnicalContent: Bool {
        currentRole == .technician || currentRole == .admin
    }

    private var canUseTechnicianActions: Bool {
        currentRole == .technician || currentRole == .admin
    }

    private var canUseOfficeActions: Bool {
        currentRole == .office || currentRole == .admin
    }

    private var canResetWorkflow: Bool {
        currentRole == .technician || currentRole == .admin
    }

    private var canProcessOfficeInspection: Bool {
        inspection.canProcessByOffice
    }

    private var canMarkInspectionInvoiced: Bool {
        inspection.workflowStatus == .processedByOffice
    }

    private func exportPDF() {
        guard inspection.canExportPDF else {
            exportErrorMessage = "Legg til minst én maskin før PDF genereres."
            return
        }

        do {
            exportedPDFURL = try InspectionPDFExporter.export(inspection: inspection)
            exportErrorMessage = nil
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func exportCertificateBasis() {
        guard inspection.canExportCertificateBasis else {
            exportErrorMessage = "Legg inn sertifikatnummer og minst én maskin før sertifikatgrunnlaget lages."
            return
        }

        do {
            certificateBasisURL = try CertificateBasisExporter.export(inspection: inspection)
            exportErrorMessage = nil
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private var exportAlertIsPresented: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    exportErrorMessage = nil
                }
            }
        )
    }

    private var completionAlertIsPresented: Binding<Bool> {
        Binding(
            get: { completionErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    completionErrorMessage = nil
                }
            }
        )
    }
}

private struct OfficeCheckRow: View {
    let title: String
    let isComplete: Bool

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isComplete ? .green : .orange)
        }
    }
}
