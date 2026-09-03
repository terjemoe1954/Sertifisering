import SwiftUI
import SwiftData

struct InspectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var inspection: Inspection
    @State private var exportedPDFURL: URL?
    @State private var exportErrorMessage: String?

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
                Picker("Status", selection: $inspection.status) {
                    ForEach(InspectionStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
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
}
