import SwiftUI
import SwiftData

struct InspectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var inspection: Inspection
    @State private var exportedPDFURL: URL?
    @State private var exportErrorMessage: String?
    @State private var completionErrorMessage: String?

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

                Button("Marker ferdig fra tekniker", systemImage: "checkmark.seal", action: completeTechnicianInspection)
                    .disabled(!canCompleteTechnicianInspection || inspection.workflowStatus != .draft)

                Button("Marker behandlet av kontor", systemImage: "tray.full", action: processOfficeInspection)
                    .disabled(!canProcessOfficeInspection)

                Button("Marker fakturert", systemImage: "checkmark.circle", action: markInspectionInvoiced)
                    .disabled(!canMarkInspectionInvoiced)

                if !canCompleteTechnicianInspection && inspection.workflowStatus == .draft {
                    Text("Fyll ut firma/eier, kontrollør og legg til minst én maskin før kontrollen fullføres.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if inspection.workflowStatus != .draft {
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
            }

            Section("Maskiner") {
                if inspection.machines.isEmpty {
                    Text("Ingen maskiner lagt til")
                        .foregroundStyle(.secondary)
                }

                ForEach(inspection.machines) { machine in
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

                Button("Legg til maskin", systemImage: "plus", action: addMachine)
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

                if let exportedPDFURL {
                    ShareLink(
                        item: exportedPDFURL,
                        preview: SharePreview("Sertifiseringsrapport", image: Image(systemName: "doc.richtext"))
                    ) {
                        Label("Del PDF", systemImage: "square.and.arrow.up")
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
        inspection.machines.append(machine)
        modelContext.insert(machine)
    }

    private func deleteMachines(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(inspection.machines[index])
        }
    }

    private func completeTechnicianInspection() {
        guard canCompleteTechnicianInspection else {
            completionErrorMessage = "Fyll ut firma/eier, kontrollør og legg til minst én maskin før kontrollen fullføres."
            return
        }

        inspection.workflowStatus = .completedByTechnician
        saveChanges()
    }

    private func processOfficeInspection() {
        guard canProcessOfficeInspection else {
            completionErrorMessage = "Kontrollen må være ferdig fra tekniker før kontoret kan behandle den."
            return
        }

        inspection.workflowStatus = .processedByOffice
        saveChanges()
    }

    private func markInspectionInvoiced() {
        guard canMarkInspectionInvoiced else {
            completionErrorMessage = "Kontrollen må være behandlet av kontor før den kan markeres som fakturert."
            return
        }

        inspection.workflowStatus = .invoiced
        saveChanges()
    }

    private func resetToDraft() {
        inspection.workflowStatus = .draft
        inspection.completedAt = nil
        inspection.processedAt = nil
        inspection.invoicedAt = nil
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            completionErrorMessage = error.localizedDescription
        }
    }

    private var canCompleteTechnicianInspection: Bool {
        !inspection.companyOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inspection.inspector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inspection.machines.isEmpty
    }

    private var canProcessOfficeInspection: Bool {
        inspection.workflowStatus == .completedByTechnician || inspection.workflowStatus == .readyForOffice
    }

    private var canMarkInspectionInvoiced: Bool {
        inspection.workflowStatus == .processedByOffice
    }

    private func exportPDF() {
        do {
            exportedPDFURL = try InspectionPDFExporter.export(inspection: inspection)
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
